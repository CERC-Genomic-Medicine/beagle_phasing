process ref_vcf2chrom {
	//debug true

	executor "local"

	input:
	tuple file(vcf), file(vcf_index)

	output:
	tuple stdout, file(vcf), file(vcf_index)

	"""
	n_chrom=`bcftools index -s ${vcf} | wc -l`
	if [[ \${n_chrom} -gt 1 ]]; then
		echo "Multiple chromosomes within one reference panel VCF are not allowed." 1>&2
		exit 1
	fi
	chrom=`bcftools index -s ${vcf} | cut -f1`
	printf "\${chrom}"
	"""
}


process study_vcf2chrom {
	//debug true

	executor "local"

	input:
	tuple file(vcf), file(vcf_index)

	output:
	tuple stdout, file(vcf), file(vcf_index)

	"""
	n_chrom=`bcftools index -s ${vcf} | wc -l`
	if [[ \${n_chrom} -gt 1 ]]; then
		echo "Multiple chromosomes within one study VCF are not allowed." 1>&2
		exit 1
	fi
	chrom=`bcftools index -s ${vcf} | cut -f1`
	printf "\${chrom}"
	"""
}


process phase_auto_chrom {
	label "PHASING"

	cache "lenient"
        //scratch true
        errorStrategy { sleep(Math.pow(2, task.attempt) * 200 as long); return "retry" }
	maxRetries 0

	input:
	tuple val(chrom), file(study_vcf), file(study_vcf_index), file(ref_vcf), file(ref_vcf_index), file(genetic_map)

        output:
	file "${study_vcf.getBaseName()}.phased.vcf.gz"
	file "${study_vcf.getBaseName()}.phased.log"

	publishDir "Results", pattern: "${study_vcf.getBaseName()}.phased*", mode: "copy"


	"""
	${params.beagle_cmd} gt=${study_vcf} ref=${ref_vcf} map=${genetic_map} chrom=${chrom} out=${study_vcf.getBaseName()}.phased
	"""
}


workflow {
	ref_vcfs = Channel.fromPath(params.reference_vcfs).map{ vcf -> [ vcf, vcf + (file(vcf + ".tbi").exists() ? ".tbi" : ".csi") ] }
        study_vcfs = Channel.fromPath(params.study_vcfs).map{ vcf -> [ vcf, vcf + (file(vcf +  ".tbi").exists() ? ".tbi" : ".csi") ] }
        
	ref_vcf2chrom(ref_vcfs)
	study_vcf2chrom(study_vcfs)

	// split autosomals and X chromosome
	ref_vcf2chrom.out.branch {
		auto_chroms: it[0] =~ /^(chr?)[1-9][0-9]*$/
		x_chrom: it[0] =~ /^(chr?)X$/
	}.set{ ref }

	study_vcf2chrom.out.branch {
		auto_chroms: it[0] =~ /^(chr?)[1-9][0-9]*$/
		x_chrom: it[0] =~ /^(chr?)X$/
	}.set{ study }

	// group  study and reference files by chromosome
	study_ref_auto_chroms = study.auto_chroms.combine(ref.auto_chroms, by: 0).map { it -> it + [ file("$workflow.projectDir/Genetic_maps/plink.${it[0]}.GRCh38.map") ] }

	phase_auto_chrom(study_ref_auto_chroms)
}
