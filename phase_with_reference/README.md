# Prerequisites

1. Download the latest Beagle `jar` file from `https://faculty.washington.edu/browning/beagle/beagle.html`.
2. Clone this repository:
    ```
    git clone https://github.com/CERC-Genomic-Medicine/beagle_phasing.git
    cd beagle_phasing/phase_with_reference
    ```
2. Download genetic maps `zip` file for build **GRCh38** from `https://bochet.gcc.biostat.washington.edu/beagle/genetic_maps/` into `Genetic_maps` directory, unzip and fix chromosome names:
    ```
    mkdir Genetic_maps
    cd Genetic_maps
    wget https://bochet.gcc.biostat.washington.edu/beagle/genetic_maps/plink.GRCh38.map.zip
    unzip plink.GRCh38.map.zip
    for f in *.map; do sed -i 's/^/chr/' ${f}; done
    cd ..
    ```
3. Edit the `nextflow.config` file accordingly.
4. Load `bcftools` and `nextflow` modules:
    ```
    module load bcftools
    module load nextflow
    ```
5. Run nextflow e.g.:
    ```
    nextflow run Pipeline.nf
    ```
