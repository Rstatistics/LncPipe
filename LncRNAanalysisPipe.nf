#!/usr/bin/env nextflow

/*
 * LncPipe was implemented by Dr. Qi Zhao from Sun Yat-sen University Cancer Center.
 *
 *
 *   LncPipe is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU General Public License as published by
 *   the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *      See the GNU General Public License for more details.
 *
 *   You should have received a copy of the GNU General Public License
 *   along with RNA-Toy.  If not, see <http://www.gnu.org/licenses/>.
 */

/*
 * LncPipe: A nextflow-based lncRNA identification and analysis pipeline from RNA sequencing data
 *
 * Authors:
 * Qi Zhao <zhaoqi@sysucc.org.cn>: design and implement the pipeline.
 * Yu Sun <sun_yu@mail.nankai.edu.cn>: design and implement the analysis report sections.
 * Zhixiang Zuo <zuozhx@sysucc.org.cn>: design the project and perform the testing.
 */

// requirement:
// - fastqc／AfterQC
// - STAR/tophat2/bowtie2/hisat2/StringTie
// - samtools/sambamba
// - Cufflinks/gffcompare
// - Bedops
// - CPAT
// - PLEK
// - CNCI
// - kallisto [https://pachterlab.github.io/kallisto/starting]

//pre-defined functions for render command
//=======================================================================================
ANSI_RESET = "\u001B[0m";
ANSI_BLACK = "\u001B[30m";
ANSI_RED = "\u001B[31m";
ANSI_GREEN = "\u001B[32m";
ANSI_YELLOW = "\u001B[33m";
ANSI_BLUE = "\u001B[34m";
ANSI_PURPLE = "\u001B[35m";
ANSI_CYAN = "\u001B[36m";
ANSI_WHITE = "\u001B[37m";


def print_red = {  str -> ANSI_RED + str + ANSI_RESET }
def print_black = {  str -> ANSI_BLACK + str + ANSI_RESET }
def print_green = {  str -> ANSI_GREEN + str + ANSI_RESET }
def print_yellow = {  str -> ANSI_YELLOW + str + ANSI_RESET }
def print_blue = {  str -> ANSI_BLUE + str + ANSI_RESET }
def print_cyan = {  str -> ANSI_CYAN + str + ANSI_RESET }
def print_purple = {  str -> ANSI_PURPLE + str + ANSI_RESET }
def print_white = {  str -> ANSI_WHITE + str + ANSI_RESET }

version = '0.0.4'
//Help information
// Pipeline version

//=======================================================================================
//help information
params.help = null
if (params.help) {
    log.info ''
    log.info print_purple('------------------------------------------------------------------------')
    log.info "LncPipe: a Nextflow-based Long non-coding RNA analysis PIPELINE v$version"
    log.info "LncPipe integrates several NGS processing tools to identify novel long non-coding RNAs from"
    log.info "unprocessed RNA sequencing data. Before run this pipeline, users need to install several tools"
    log.info "unprocessed RNA sequencing data. Before run this pipeline, users need to install several tools"
    log.info print_purple('------------------------------------------------------------------------')
    log.info ''
    log.info print_yellow('Usage: ')
    log.info print_yellow('    The typical command for running the pipeline is as follows:\n') +
            print_purple('       Nextflow lncRNApipe.nf \n') +

            print_yellow('    Mandatory arguments:             Input and output setting\n') +
            print_cyan('      --input_folder                ') + print_green('Path to input data(optional), current path default\n') +
            print_cyan('      --fastq_ext                   ') + print_green('Filename pattern for pairing raw reads, e.g: *_{1,2}.fastq.gz for paired reads\n') +
            print_cyan('      --out_folder                  ') + print_green('The output directory where the results will be saved(optional), current path is default\n') +
            print_cyan('      --aligner                     ') + print_green('Aligner for reads mapping (optional), STAR is default and supported only at present\n') +
            print_cyan('      --qctools                     ') + print_green('Tools for assess reads quality, fastqc/afterqc\n') +
            '\n' +
            print_yellow('    Options:                         General options for run this pipeline\n') +
            print_cyan('      --merged_gtf                  ') + print_green('Start analysis with assemblies already produced and skip fastqc/alignment step, DEFAOUL NULL\n') +
            print_cyan('      --design                      ') + print_green('A flat file stored the experimental design information ( required when perform differential expression analysis)\n') +

            '\n' +
            print_yellow('    References:                      If not specified in the configuration file or you wish to overwrite any of the references.\n') +
            print_cyan('      --fasta                       ') + print_green('Path to Fasta reference(required)\n') +
            print_cyan('      --gencode_annotation_gtf      ') + print_green('An annotation file from GENCODE database for annotating lncRNAs(required)\n') +
            print_cyan('      --lncipedia_gtf               ') + print_green('An annotation file from LNCipedia database for annotating lncRNAs(required)\n') +
            print_cyan('      --rRNAmask                    ') + print_green('rRNA GTF for removing rRNA transcript from gtf files(required)\n') +
            '\n' +
            print_yellow('    LncPipeReporter Options:         LncPipeReporter setting  \n') +
            print_cyan('      --lncRep_Output                ') + print_green('Specify report file name, \"report.html\" default.\n') +
            print_cyan('      --lncRep_theme                 ') + print_green('Plot theme setting in interactive plot, \"npg\" default.\n') +
            print_cyan('      --lncRep_min_expressed_sample  ') + print_green('Minimum expressed gene allowed in each sample, 50 default.\n') +
            '\n' +
            print_yellow('    Other options:                   Specify the email and \n') +
            print_cyan('      --sam_processor                ') + print_green('program to process samfile generated by hisat2 if aligner is hisat2. Default \"sambamba\". \n') +



            log.info '------------------------------------------------------------------------'
    log.info print_yellow('Contact information: zhaoqi@sysucc.org.cn')
    log.info print_yellow('Copyright (c) 2013-2017, Sun Yat-sen University Cancer Center.')
    log.info '------------------------------------------------------------------------'
    exit 0
}

//default values
params.input_folder = './'
params.out_folder = './'

// Reference
// already defined in nextflow.config file
// Set reference information here if you don't want to pass them from parameter any longer, we recommand users using the latest reference and the annotation file with the sample genome version.
//params.fasta_ref = '/data/database/human/hg38/genome.fa'
//params.star_idex = '/data/database/human/hg38/RSEM_STAR_Index'
//params.bowtie2_index=false
//params.gencode_annotation_gtf = "/data/database/human/hg38/annotation/gencode.v24.annotation.gtf"
//params.lncipedia_gtf = "/data/database/human/hg38/annotation/lncipedia_4_0_hg38.gtf"
//params.rRNAmask = "/data/database/human/hg38/annotation/hg38_rRNA.gtf";
//// software path
//params.plekpath = '/home/zhaoqi/software/PLEK.1.2/'
////params.cncipath = '/data/software/CNCI-master'
//params.cpatpath = '/home/zhaoqi/software/CPAT/CPAT-1.2.2/'
//params.fasta_ref = null
//params.star_idex = null
//params.bowtie2_index = null
//params.gencode_annotation_gtf = null
//params.lncipedia_gtf = null
//params.rRNAmask = null
//params.fastq_ext = null
//params.cpatpath = null
//params.plekpath = null
//aligner

params.merged_gtf = null


singleEnd = params.singleEnd ? "true" : "false"
skip_combine = params.skip_combine ? "true" : "false"

//Checking parameters
log.info print_purple("You are running LncPipe with the following parameters:")
log.info print_purple("Checking parameters ...")
log.info print_yellow("=====================================")
log.info print_yellow("Fastq file extention:           ") + print_green(params.fastq_ext)
log.info print_yellow("Single end :                    ") + print_green(params.singleEnd)
log.info print_yellow("skip annotation process:        ") + print_green(params.skip_combine)
log.info print_yellow("Input folder:                   ") + print_green(params.input_folder)
log.info print_yellow("Output folder:                  ") + print_green(params.out_folder)
log.info print_yellow("Genome sequence location:       ") + print_green(params.fasta_ref)
log.info print_yellow("Star index path:                ") + print_green(params.star_idex)
log.info print_yellow("hisat index path:                ") + print_green(params.hisat2_index)
log.info print_yellow("bowtie/tophat index path:                ") + print_green(params.bowtie2_index)
log.info print_yellow("GENCODE annotation location:    ") + print_green(params.gencode_annotation_gtf)
log.info print_yellow("lncipedia ann0tation location:  ") + print_green(params.lncipedia_gtf)
log.info print_yellow("rRNA annotation location:       ") + print_green(params.rRNAmask)
log.info print_yellow("=====================================")
log.info "\n"

// run information of system file
//automatic set optimize resource for analysis based on current system resources
ava_mem = (double) (Runtime.getRuntime().freeMemory())
ava_cpu = Runtime.getRuntime().availableProcessors()
if (params.cpu != null && ava_cpu > params.cpu) {
    ava_cpu = params.cpu
} else if (params.cpu != null && ava_cpu < params.cpu) {
    print print_red("Cpu number set in command is not used for exceeding the max available processors, \n use default parameter to run pipe. ")
}
if (params.mem != null && ava_mem > params.mem) {
    ava_mem = params.mem
} else if (params.mem != null && ava_mem < params.mem) {
    print print_red("Memory set in command is not used for exceeding the max available processors, \n use default parameter to run pipe. ")
}
// set individual cpu for fork run
idv_cpu = 40
int fork_number = ava_cpu / idv_cpu
if (fork_number < 1) {
    fork_number = 1
}

// read file
fasta_ref = file(params.fasta_ref)
if (!fasta_ref.exists()) exit 1, "Reference genome not found: ${params.fasta_ref}"

if(params.aligner=='star'){
    star_idex = file(params.star_idex)
    if (!star_idex.exists()) exit 1, "Reference genome star index not found: ${params.star_idex}"
}else if(params.aligner =='hisat'){
    hisat2_index = Channel.fromPath("${params.hisat2_index}*")
            .ifEmpty { exit 1, "HISAT2 index not found: ${params.hisat2_index}" }
}else if(params.aligner =='tophat'){
    bowtie2_index = Channel.fromPath("${params.bowtie2_index}*")
            .ifEmpty { exit 1, "bowtie2 index for tophat not found: ${params.bowtie2_index}" }
}









input_folder = file(params.input_folder)
gencode_annotation_gtf = file(params.gencode_annotation_gtf)
lncipedia_gtf = file(params.lncipedia_gtf)
//cncipath = file(params.cncipath)
rRNAmaskfile = file(params.rRNAmask)

//Prepare annotations
annotation_channel = Channel.from(gencode_annotation_gtf, lncipedia_gtf)
annotation_channel.collectFile { file -> ['lncRNA.gtflist', file.name + '\n'] }
        .set { LncRNA_gtflist }

/*
*Step 1: Preparing annotations
 */

println print_purple("Combination of known annotations from GTFs")
process combine_public_annotation {
    storeDir { params.out_folder + "/Combined_annotations" }
    input:
    file lncRNA_gtflistfile from LncRNA_gtflist
    file gencode_annotation_gtf
    file lncipedia_gtf

    output:
    file "gencode_protein_coding.gtf" into proteinCodingGTF, proteinCodingGTF_forClass
    file "known.lncRNA.gtf" into KnownLncRNAgtf

    shell:
    cufflinks_threads = ava_cpu- 1

    if(params.aligner=='hisat'){
        '''
        set -o pipefail
        touch filenames.txt
        for file in *.gtf 
        do
        perl -lpe 's/ [^"](\\S+) ;/ "$1" ;/g\' $file > ${file}_mod.gtf 
        echo ${file}_mod.gtf >>filenames.txt
        
        done
        
        stringtie --merge -o merged_lncRNA.gtf  filenames.txt
        cat !{gencode_annotation_gtf}_mod.gtf  |grep "protein_coding" > gencode_protein_coding.gtf
        gffcompare -r !{gencode_annotation_gtf} -p !{cufflinks_threads} merged_lncRNA.gtf
        awk '$3 =="u"||$3=="x"{print $5}' gffcmp.merged_lncRNA.gtf.tmap |sort|uniq|perl !{baseDir}/bin/extract_gtf_by_name.pl merged_lncRNA.gtf - > merged.filter.gtf
        mv  merged.filter.gtf known.lncRNA.gtf
        
        '''
    }else {

        '''
        set -o pipefail
        cuffmerge -o merged_lncRNA  !{lncRNA_gtflistfile}
        cat !{gencode_annotation_gtf} |grep "protein_coding" > gencode_protein_coding.gtf
        cuffcompare -o merged_lncRNA -r !{gencode_annotation_gtf} -p !{cufflinks_threads} merged_lncRNA/merged.gtf
        awk '$3 =="u"||$3=="x"{print $5}' merged_lncRNA/merged_lncRNA.merged.gtf.tmap  |sort|uniq|perl !{baseDir}/bin/extract_gtf_by_name.pl merged_lncRNA/merged.gtf - > merged.filter.gtf
        mv  merged.filter.gtf known.lncRNA.gtf
        
        '''
    }


}

// whether the merged gtf have already produced.
if (!params.merged_gtf) {

    /*
     * Step 2: Build STAR/tophat/hisat2 index if not provided
     */
    //star_index if not exist
    if (params.aligner == 'star' && params.star_idex == false && fasta_ref) {
        process Make_STARindex {
            tag fasta_ref

            storeDir { params.out_folder + "/STARIndex" }

            input:
            file fasta_ref from fasta_ref
            file gtf from gencode_annotation_gtf

            output:
            file "star_index" into star_idex

            shell:
            star_threads = ava_cpu- 1
            """
                mkdir star_index
                STAR \
                    --runMode genomeGenerate \
                    --runThreadN ${star_threads} \
                    --sjdbGTFfile $gtf \
                    --sjdbOverhang 149 \
                    --genomeDir star_index/ \
                    --genomeFastaFiles $fasta_ref
                """
        }
    } else if (params.aligner == 'star' && params.star_idex == false && !fasta_ref) {
        println print_red("No reference sequence loaded! plz specify ") + print_red("--fasta_ref") + print_red(" with reference.")

    } else if (params.aligner == 'tophat' && params.bowtie2_index == false && !fasta_ref) {
        process Make_bowtie2_index {
            tag fasta_ref
            storeDir { params.out_folder + "/bowtie2Index" }

            input:
            file fasta_ref from fasta_ref

            output:
            file "genome_bt2.*" into bowtie2_index

            shell:
            """
                bowtie2-build !{fasta_ref} genome_bt2
                """
        }
    } else if (params.aligner == 'tophat' && !fasta_ref) {
        println print_red("No reference sequence loaded! plz specify ") + print_red("--fasta_ref") + print_red(" with reference.")
    } else if (params.aligner == 'hisat2' && !fasta_ref) {
        process Make_hisat_index {
            tag fasta_ref

            storeDir { params.out_folder + "/hisatIndex" }

            input:
            file fasta_ref from fasta_ref
            file gencode_annotation_gtf from gencode_annotation_gtf

            output:
            file "genome_ht2.*" into hisat2_index

            shell:
            hisat2_index_threads = ava_cpu- 1
            """
                #for human genome it will take more than 160GB memory and take really  long time (6 more hours), thus we recommand to down preduild genome from hisat website
                extract_splice_sites.py gencode_annotation_gtf >genome_ht2.ss
                extract_exons.py gencode_annotation_gtf > genome_ht2.exon 
                hisat2-build -p !{hisat2_index_threads} --ss genome_ht2.ss --exo genome_ht2.exon !{fasta_ref} genome_ht2 
                """
        }
    } else if (params.aligner == 'tophat' && params.hisat_index == false && !fasta_ref) {
        println print_red("No reference sequence loaded! plz specify ") + print_red("--fasta_ref") + print_red(" with reference.")
    }





    println print_purple("Analysis from fastq file")
//Match the pairs on two channels

    reads = params.input_folder + params.fastq_ext

    /*
    * Step 2: FastQC/AfterQC raw reads
    */
    println print_purple("Perform quality control of raw fastq files ")
    if (params.qctools == 'fastqc') {
        Channel.fromFilePairs(reads, size: params.singleEnd ? 1 : 2)
                .ifEmpty {
            exit 1, print_red("Cannot find any reads matching: !{reads}\nNB: Path needs to be enclosed in quotes!\n")
        }
        .into { reads_for_fastqc; readPairs_for_discovery;readPairs_for_kallisto}
        process Run_fastQC {
            tag { fastq_tag }
            publishDir pattern: "*.html",
                    path: { params.out_folder + "/Result/QC" }, mode: 'copy', overwrite: true

            input:
            set val(samplename), file(fastq_file) from reads_for_fastqc

            output:
            file "*.html" into fastqc_for_waiting
            shell:
            fastq_tag = samplename
            fastq_threads = idv_cpu - 1
            '''
            fastqc -t !{fastq_threads} !{fastq_file[0]} !{fastq_file[1]}
        '''
        }
    }
    else {
        Channel.fromFilePairs(reads, size: params.singleEnd ? 1 : 2)
                .ifEmpty {
            exit 1, print_red("Cannot find any reads matching: !{reads}\nPlz check your fasta_ref string in nextflow.config file \n")
        }
        .set { reads_for_fastqc}
        process Run_afterQC {

            tag { fastq_tag }

            publishDir pattern: "QC/*.html",
                    path: { params.out_folder + "/Result/QC" }, mode: 'copy', overwrite: true

            input:
            set val(samplename), file(fastq_file) from reads_for_fastqc

            output:
            file "QC/*.html" into fastqc_for_waiting
            file "*.good.fq" into readPairs_for_discovery,readPairs_for_kallisto
            shell:
            fastq_tag = samplename
            fastq_threads = idv_cpu - 1
            if (params.singleEnd) {
                '''
            after.py -1 !{fastq_file[0]} -g ./
            '''
            } else {
                '''
            after.py -1 !{fastq_file[0]} -2 !{fastq_file[1]} -g ./
            '''
            }
        }
    }
    fastqc_for_waiting = fastqc_for_waiting.first()


    /*
    * Step 4: Initialized reads alignment by STAR
    */
    if (params.aligner == 'star') {
        process fastq_star_alignment_For_discovery {

            tag { file_tag }

            publishDir pattern: "",
                    path: { params.out_folder + "/Result/Star_alignment" }, mode: 'copy', overwrite: true

            input:
            set val(samplename), file(pair) from readPairs_for_discovery
            file tempfiles from fastqc_for_waiting // just for waiting
            file fasta_ref
            file star_idex

            output:
            set val(file_tag_new), file("${file_tag_new}Aligned.sortedByCoord.out.bam") into mappedReads
            file "${file_tag_new}Log.final.out" into alignment_logs
            shell:
            println print_purple("Start mapping with STAR aligner " + samplename)
            file_tag = samplename
            file_tag_new = file_tag
            star_threads = ava_cpu - 1

            if (params.singleEnd) {
                println print_purple("Initial reads mapping of " + samplename + " performed by STAR in single-end mode")
                """
                         STAR --runThreadN !{star_threads} \
                            --twopassMode Basic \
                            --genomeDir !{star_idex} \
                            --readFilesIn !{pair} \
                            --readFilesCommand zcat \
                            --outSAMtype BAM SortedByCoordinate \
                            --chimSegmentMin 20 \
                            --outFilterIntronMotifs RemoveNoncanonical \
                            --outFilterMultimapNmax 20 \
                            --alignIntronMin 20 \
                            --alignIntronMax 1000000 \
                            --alignMatesGapMax 1000000 \
                            --outFilterType BySJout \
                            --alignSJoverhangMin 8 \
                            --alignSJDBoverhangMin 1 \
                            --outFileNamePrefix !{file_tag_new} 
                    """
            } else {
                println print_purple("Initial reads mapping of " + samplename + " performed by STAR in paired-end mode")
                '''
                            STAR --runThreadN !{star_threads}  \
                                 --twopassMode Basic --genomeDir !{star_idex} \
                                 --readFilesIn !{pair[0]} !{pair[1]} \
                                 --readFilesCommand zcat \
                                 --outSAMtype BAM SortedByCoordinate \
                                 --chimSegmentMin 20 \
                                 --outFilterIntronMotifs RemoveNoncanonical \
                                 --outFilterMultimapNmax 20 \
                                 --alignIntronMin 20 \
                                 --alignIntronMax 1000000 \
                                 --alignMatesGapMax 1000000 \
                                 --outFilterType BySJout \
                                 --alignSJoverhangMin 8 \
                                 --alignSJDBoverhangMin 1 \
                                 --outFileNamePrefix !{file_tag_new} 
                    '''
            }
        }
    }
    else if (params.aligner == 'tophat')
    {
        process fastq_tophat_alignment_For_discovery {

            tag { file_tag }

            publishDir pattern: "",
                    path: { params.out_folder + "/Result/tophat_alignment" }, mode: 'copy', overwrite: true

            input:
            set val(samplename), file(pair) from readPairs_for_discovery
            file tempfiles from fastqc_for_waiting // just for waiting
            file fasta_ref
            file bowtie2_index from bowtie2_index.collect()
            file gtf from gencode_annotation_gtf

            output:
             file "${file_tag_new}_thout/accepted.bam" into mappedReads
            file "${file_tag_new}_thout/Alignment_summary.txt" into alignment_logs
            //align_summary.txt as log file
            shell:
            println print_purple("Start mapping with tophat2 aligner " + samplename)
            file_tag = samplename
            file_tag_new = file_tag
            tophat_threads = ava_cpu- 1
            index_base = bowtie2_index[0].toString() - ~/.\d.bt2/
            if (params.singleEnd) {
                println print_purple("Initial reads mapping of " + samplename + " performed by Tophat in single-end mode")
                '''
                         tophat -p !{tophat_threads} -G !{gtf} -–no-novel-juncs -o !{samplename}_thout !{index_base} !{pair} 
                         
                '''
            } else {
                println print_purple("Initial reads mapping of " + samplename + " performed by Tophat in paired-end mode")
                '''
                     tophat -p !{tophat_threads} -G !{gtf} -–no-novel-juncs -o !{samplename}_thout !{index_base} !{pair[0]} !{pair[1]} 
                '''
            }
        }
    }
    else if (params.aligner == 'hisat') {
        process fastq_hisat2_alignment_For_discovery {

            tag { file_tag }
            maxForks 1
            publishDir pattern: "",
                    path: { params.out_folder + "/Result/hisat_alignment" }, mode: 'copy', overwrite: true

            input:
            set val(samplename), file(pair) from readPairs_for_discovery
            file tempfiles from fastqc_for_waiting // just for waiting
            file fasta_ref
            file hisat2_id from hisat2_index.collect()
            file gtf from gencode_annotation_gtf

            output:
            set val(file_tag_new),file("${file_tag_new}.sort.bam") into hisat_mappedReads
            file "${file_tag_new}.hisat2_summary.txt" into alignment_logs
            //align_summary.txt as log file
            shell:
            println print_purple("Start mapping with hisat2 aligner " + samplename)
            file_tag = samplename
            file_tag_new = file_tag
            hisat2_threads = ava_cpu- 2
            index_base = hisat2_id[0].toString() - ~/.\d.ht2/
            if (params.singleEnd) {
                println print_purple("Initial reads mapping of " + samplename + " performed by hisat2 in single-end mode")
                '''
                   hisat2  -p !{hisat2_threads} --dta  -x  !{index_base}  -U !{pair}  -S !{file_tag_new}.sam 2>!{file_tag_new}.hisat2_summary.txt
                  sambamba view -S -f bam -t !{hisat2_threads} !{file_tag_new}.sam -o temp.bam 
                  sambamba sort -o !{file_tag_new}.sort.bam -t !{hisat2_threads} temp.bam
                  rm !{file_tag_new}.sam
                  rm temp.bam
                  
                '''
            } else {
                println print_purple("Initial reads mapping of " + samplename + " performed by hisat2 in paired-end mode")
                '''
                  hisat2  -p !{hisat2_threads} --dta  -x  !{index_base}  -1 !{pair[0]}  -2 !{pair[1]}  -S !{file_tag_new}.sam 2> !{file_tag_new}.hisat2_summary.txt
                  sambamba view -S -f bam -t !{hisat2_threads} !{file_tag_new}.sam -o temp.bam
                  sambamba sort -o !{file_tag_new}.sort.bam -t !{hisat2_threads} temp.bam
                  rm !{file_tag_new}.sam
                '''
            }
        }
    }

    /*
    * Step 5: Reads assembling by using stringtie
    */
    if(params.aligner == 'hisat'){
        process StringTie_assembly {

            tag { file_tag }

            input:
            set val(samplename),file(alignment_bam) from hisat_mappedReads
            file fasta_ref
            file gencode_annotation_gtf

            output:

            file "stringtie_${file_tag_new}_transcripts.gtf" into stringTieoutgtf, StringTieOutGtf_fn

            shell:
            file_tag = samplename
            file_tag_new = file_tag
            stringtie_threads = ava_cpu- 2

            '''
            #run stringtie
            stringtie -p !{stringtie_threads} -G !{gencode_annotation_gtf} --rf -l stringtie_!{file_tag_new} -o stringtie_!{file_tag_new}_transcripts.gtf !{alignment_bam}
            '''
        }
// Create a file 'gtf_filenames' containing the filenames of each post processes cufflinks gtf
        stringTieoutgtf.collectFile { file -> ['gtf_filenames.txt', file.name + '\n'] }
                .set { GTFfilenames }
        /*
        * Step 6: Merged GTFs into one
        */
        process StringTie_merge_assembled_gtf {

            tag { file_tag }
            publishDir pattern: "StringTie/merged.gtf",
                    path: { params.out_folder + "/Result/Merged_assemblies" }, mode: 'copy', overwrite: true

            input:
            file gtf_filenames from GTFfilenames
            file cufflinksgtf_file from StringTieOutGtf_fn.toList() // not used but just send the file in current running folder
            file fasta_ref


            output:
            file "merged.gtf" into mergeTranscripts_forCompare, mergeTranscripts_forExtract, mergeTranscripts_forCodeingProtential
            shell:

            stringtie_threads = ava_cpu- 1

            '''
            stringtie --merge -p !{stringtie_threads} -o merged.gtf !{gtf_filenames}
            
            
            '''
        }
    }
    else{
        process Cufflinks_assembly {

            tag { file_tag }

            input:
            set val(file_tag), file(alignment_bam) from mappedReads
            file fasta_ref
            file gencode_annotation_gtf

            output:

            file "Cufout_${file_tag_new}_transcripts.gtf" into cuflinksoutgtf, cuflinksoutgtf_fn

            shell:
            file_tag_new = file_tag
            cufflinks_threads = ava_cpu- 1
            if (params.aligner == 'tophat') {
                '''
            #run cufflinks
            
            cufflinks -g !{gencode_annotation_gtf} \
                      -b !{fasta_ref} \
                      --library-type fr-firststrand \
                      --max-multiread-fraction 0.25 \
                      --3-overhang-tolerance 2000 \
                      -o Cufout_!{file_tag_new} \
                      -p !{cufflinks_threads} !{alignment_bam}
                      
            mv Cufout_!{file_tag_new}/transcripts.gtf Cufout_!{file_tag_new}_transcripts.gtf
            '''

            } else if (params.aligner == 'star') {
                '''
            #run cufflinks
            
            cufflinks -g !{gencode_annotation_gtf} \
                      -b !{fasta_ref} \
                      --library-type fr-firststrand \
                      --max-multiread-fraction 0.25 \
                      --3-overhang-tolerance 2000 \
                      -o Cufout_!{file_tag_new} \
                      -p !{cufflinks_threads} !{alignment_bam}
                      
            mv Cufout_!{file_tag_new}/transcripts.gtf Cufout_!{file_tag_new}_transcripts.gtf
            '''

            }


        }

// Create a file 'gtf_filenames' containing the filenames of each post processes cufflinks gtf

        cuflinksoutgtf.collectFile { file -> ['gtf_filenames.txt', file.name + '\n'] }
                .set { GTFfilenames }

        /*
        * Step 6: Merged GTFs into one
        */
        process cuffmerge_assembled_gtf {

            tag { file_tag }
            publishDir pattern: "CUFFMERGE/merged.gtf",
                    path: { params.out_folder + "/Result/All_assemblies" }, mode: 'copy', overwrite: true

            input:
            file gtf_filenames from GTFfilenames
            file cufflinksgtf_file from cuflinksoutgtf_fn.toList() // not used but just send the file in current running folder

            file fasta_ref


            output:
            file "CUFFMERGE/merged.gtf" into mergeTranscripts_forCompare, mergeTranscripts_forExtract, mergeTranscripts_forCodeingProtential
            shell:

            cufflinks_threads = ava_cpu- 1

            '''
            mkdir CUFFMERGE
            cuffmerge -o CUFFMERGE \
                      -s !{fasta_ref} \
                      -p !{cufflinks_threads} \
                         !{gtf_filenames}
            
            '''
        }
    }


} else {
    println print_yellow("FastaQC step was skipped due to provided ") + print_green("--merged_gtf") + print_yellow(" option\n")
    println print_yellow("Reads mapping step was skipped due to provided ") + print_green("--merged_gtf") + print_yellow(" option\n")

    merged_gtf = file(params.merged_gtf)
    Channel.fromPath(merged_gtf)
            .ifEmpty { exit 1, "Cannot find merged gtf : ${merged_gtf}" }
            .into {
        mergeTranscripts_forCompare; mergeTranscripts_forExtract; mergeTranscripts_forCodeingProtential
    }

}

/*
*Step 7: Comparing assembled gtf with known ones (GENCODE)
*/
    process Merge_assembled_gtf_with_GENCODE {

        tag { file_tag }
        input:
        file mergeGtfFile from mergeTranscripts_forCompare
        file gencode_annotation_gtf

        output:
        file "merged_lncRNA.merged.gtf.tmap" into comparedGTF_tmap
        shell:

        gffcompare_threads = ava_cpu- 1
        '''
        #!/bin/sh
        gffcompare -r !{gencode_annotation_gtf} -p !{gffcompare_threads} !{mergeGtfFile} -o merged_lncRNA
        '''
    }



/*
*Step 8: Filtered GTFs to distinguish novel lncRNAS
*/
process Identify_novel_lncRNA_with_criterions {

    input:
    file comparedTmap from comparedGTF_tmap
    file fasta_ref
    file mergedGTF from mergeTranscripts_forExtract

    output:
    file "novel.gtf.tmap" into noveltmap
    file "novel.longRNA.fa" into novelLncRnaFasta
    file "novel.longRNA.exoncount.txt" into novelLncRnaExonCount

    shell:
    '''
        # filtering novel lncRNA based on cuffmerged trascripts
        set -o pipefail
        awk '$3 =="x"||$3=="u"||$3=="i"{print $0}' !{comparedTmap} > novel.gtf.tmap
        #   excluding length smaller than 200 nt
        awk '$11 >200{print}' novel.gtf.tmap > novel.longRNA.gtf.tmap
        #   extract gtf
        awk '{print $5}' novel.longRNA.gtf.tmap |perl !{baseDir}/bin/extract_gtf_by_name.pl !{mergedGTF} - >novel.longRNA.gtf
        perl !{baseDir}/bin/get_exoncount.pl novel.longRNA.gtf > novel.longRNA.exoncount.txt
        # gtf2gff3
        #check whether required
        # get fasta from gtf
        gffread novel.longRNA.gtf -g !{fasta_ref} -w novel.longRNA.fa -W
     '''
}

/*
*Step 9: Predicting the potential coding abilities using CPAT, PLEK and CNCI
*/
novelLncRnaFasta.into { novelLncRnaFasta_for_PLEK; novelLncRnaFasta_for_CPAT; novelLncRnaFasta_for_CNCI }

process Predict_coding_abbilities_by_PLEK {

    // as PLEK can not return valid exit status even run smoothly, we manually set the exit status into 0 to promote analysis
    validExitStatus 0, 1, 2
    input:
    file novel_lncRNA_fasta from novelLncRnaFasta_for_PLEK
    output:
    file "novel.longRNA.PLEK.out" into novel_longRNA_PLEK_result
    shell:
    plek_threads = ava_cpu- 1
    '''
        python !{params.plekpath}/PLEK.py -fasta !{novel_lncRNA_fasta} \
                                   -out novel.longRNA.PLEK.out \
                                   -thread !{plek_threads}
	    exit 0
        '''

}
process Predict_coding_abbilities_by_CPAT {
    input:
    file novel_lncRNA_fasta from novelLncRnaFasta_for_CPAT
    output:
    file "novel.longRNA.CPAT.out" into novel_longRNA_CPAT_result
    shell:
    '''
        python !{params.cpatpath}/bin/cpat.py -g !{novel_lncRNA_fasta} \
                                       -x !{params.cpatpath}/dat/Human_Hexamer.tsv \
                                       -d !{params.cpatpath}/dat/Human_logitModel.RData \
                                       -o novel.longRNA.CPAT.out
        '''
}
//    process run_CNCI{
//
//        input:
//        file novel_lncRNA_fasta from novelLncRnaFasta_for_CNCI
//        file cncipath
//        output:
//        file lncRNA/CNCI* into novel_longRNA_CNCI_result
//        shell:
//        cnci_threads  = ava_cpu- 1
//        '''
//        python !{cncipath}/CNCI.py -f !{novel_lncRNA_fasta} -p !{cnci_threads} -o lncRNA/CNCI -m ve
//        '''
//    }

/*
*Step 9: Merged and filtered lncRNA with coding potential output
*/
process Filter_lncRNA_by_coding_potential_result {
    input:
    file novel_longRNA_PLEK_ from novel_longRNA_PLEK_result
    file novel_longRNA_CPAT_ from novel_longRNA_CPAT_result
    file longRNA_novel_exoncount from novelLncRnaExonCount
    file cuffmergegtf from mergeTranscripts_forCodeingProtential
    file gencode_annotation_gtf
    file fasta_ref

    output:
    file "novel.longRNA.stringent.gtf" into Novel_longRNA_stringent_gtf // not used
    file "novel.lncRNA.stringent.gtf" into novel_lncRNA_stringent_gtf
    file "novel.TUCP.stringent.gtf" into novel_TUCP_stringent_gtf // not used

    shell:
    '''
        set -o pipefail
        #merged transcripts
        perl !{baseDir}/bin/integrate_novel_transcripts.pl > novel.longRNA.txt
        awk '$4 >1{print $1}' novel.longRNA.txt|perl !{baseDir}/bin/extract_gtf_by_name.pl !{cuffmergegtf} - > novel.longRNA.stringent.gtf
        # retain lncRNA only by coding ability
        awk '$4 >1&&$5=="lncRNA"{print $1}' novel.longRNA.txt|perl !{baseDir}/bin/extract_gtf_by_name.pl !{cuffmergegtf} - > novel.lncRNA.stringent.gtf
        awk '$4 >1&&$5=="TUCP"{print $1}' novel.longRNA.txt|perl !{baseDir}/bin/extract_gtf_by_name.pl !{cuffmergegtf} - > novel.TUCP.stringent.gtf
        '''
}

/*
*Step 10: Further filtered lncRNAs with known criterion
*/
process Summary_renaming_and_classification {
    publishDir "${params.out_folder}/Result/Identified_lncRNA", mode: 'copy'


    input:
    file knowlncRNAgtf from KnownLncRNAgtf
    file gencode_protein_coding_gtf from proteinCodingGTF
    file novel_lncRNA_stringent_Gtf from novel_lncRNA_stringent_gtf

    output:
//    file "lncRNA.final.v2.gtf" into finalLncRNA_gtf
//    file "lncRNA.final.v2.map" into finalLncRNA_map
    file "protein_coding.final.gtf" into final_protein_coding_gtf
    file "all_lncRNA_for_classifier.gtf" into finalLncRNA_for_class_gtf
    file "final_all.gtf" into finalGTF_for_quantification_gtf, finalGTF_for_annotate_gtf
    file "final_all.fa" into finalFasta_for_quantification_gtf
    file "protein_coding.fa" into final_coding_gene_for_CPAT_fa
    file "lncRNA.fa" into final_lncRNA_for_CPAT_fa
    file "lncRNA_classification.txt" into lncRNA_classification
    //file "lncRNA.final.CPAT.out" into lncRNA_CPAT_statistic
    //file "protein_coding.final.CPAT.out" into protein_coding_CPAT_statistic

    shell:

    cufflinks_threads = ava_cpu- 1

    '''
        set -o pipefail
        gffcompare -G -o filter \
                    -r !{knowlncRNAgtf} \
                    -p !{cufflinks_threads} !{novel_lncRNA_stringent_Gtf}
        awk '$3 =="u"||$3=="x"{print $5}' filter.novel.lncRNA.stringent.gtf.tmap |sort|uniq| \
                    perl !{baseDir}/bin/extract_gtf_by_name.pl !{novel_lncRNA_stringent_Gtf} - > novel.lncRNA.stringent.filter.gtf
        
        #rename lncRNAs according to neighbouring protein coding genes
        awk '$3 =="gene"{print }' !{gencode_protein_coding_gtf} | perl -F'\\t' -lane '$F[8]=~/gene_id "(.*?)";/ && print join qq{\\t},@F[0,3,4],$1,@F[5,6,1,2,7,8,9]' - | \
            sort-bed - > gencode.protein_coding.gene.bed
        gtf2bed < novel.lncRNA.stringent.filter.gtf |sort-bed - > novel.lncRNA.stringent.filter.bed
        gtf2bed < !{knowlncRNAgtf} |sort-bed - > known.lncRNA.bed
        perl !{baseDir}/bin/rename_lncRNA_2.pl
        mv lncRNA.final.v2.gtf all_lncRNA_for_classifier.gtf
        perl !{baseDir}/bin/rename_proteincoding.pl !{gencode_protein_coding_gtf}> protein_coding.final.gtf
        cat all_lncRNA_for_classifier.gtf protein_coding.final.gtf > final_all.gtf
        gffread final_all.gtf -g !{fasta_ref} -w final_all.fa -W
        gffread all_lncRNA_for_classifier.gtf -g !{fasta_ref} -w lncRNA.fa -W
        gffread protein_coding.final.gtf -g !{fasta_ref} -w protein_coding.fa -W
        #classification 
        perl !{baseDir}/bin/lincRNA_classification.pl all_lncRNA_for_classifier.gtf !{gencode_protein_coding_gtf} lncRNA_classification.txt 
        
        
        '''
}

/*
*Step 11: Rerun CPAT to evaluate the results
*/
//lncRNA
process Rerun_CPAT_to_evaluate_lncRNA {
    input:
    file lncRNA_final_cpat_fasta from final_lncRNA_for_CPAT_fa
    output:
    file "lncRNA.final.CPAT.out" into final_lncRNA_CPAT_result
    shell:
    '''
        python !{params.cpatpath}/bin/cpat.py -g !{lncRNA_final_cpat_fasta} \
                                       -x !{params.cpatpath}/dat/Human_Hexamer.tsv \
                                       -d !{params.cpatpath}/dat/Human_logitModel.RData \
                                       -o lncRNA.final.CPAT.out
        '''

}
//coding
process Rerun_CPAT_to_evaluate_coding {
    input:
    file final_coding_gene_for_CPAT from final_coding_gene_for_CPAT_fa
    output:
    file "protein_coding.final.CPAT.out" into final_coding_gene_CPAT_result
    shell:
    '''
        python !{params.cpatpath}/bin/cpat.py -g !{final_coding_gene_for_CPAT} \
                                       -x !{params.cpatpath}/dat/Human_Hexamer.tsv \
                                       -d !{params.cpatpath}/dat/Human_logitModel.RData \
                                       -o protein_coding.final.CPAT.out
        '''
}
//summary result
process Secondary_basic_statistic {

    input:
    file protein_coding_final_gtf from final_protein_coding_gtf
    file all_lncRNA_for_classifier_gtf from finalLncRNA_for_class_gtf
    file lncRNA_cds from final_lncRNA_CPAT_result
    file coding_gene_cds from final_coding_gene_CPAT_result
    file lncRNA_class from lncRNA_classification
    output:
    file "basic_charac.txt" into statistic_result

    shell:
    '''
        #!/usr/bin/perl -w
         #since the CPAT arbitrary transformed gene names into upper case 
        #To make the gene names consistently, we apply 'uc' function to unity the gene names 
        use strict;
        open OUT,">basic_charac.txt" or die;
        
        open FH,"all_lncRNA_for_classifier.gtf" or die;
        
        my %class;
        my %g2t;
        my %trans_len;
        my %exon_num;
        while(<FH>){
        chomp;
        my @field=split "\t";
        $_=~/gene_id "(.+?)"/;
        my $gid=$1;
        $_=~/transcript_id "(.+?)"/;
        my $tid=uc($1);
        $class{$tid}=$field[1];
        $g2t{$tid}=$gid;
        my $len=$field[4]-$field[3];
        $trans_len{$tid}=(exists $trans_len{$tid})?$trans_len{$tid}+$len:$len;
        $exon_num{$tid}=(exists $exon_num{$tid})?$exon_num{$tid}+1:1;
        }
        open FH,"protein_coding.final.gtf" or die;
        
        while(<FH>){
        chomp;
        my @field=split "\t";
        $_=~/gene_id "(.+?)"/;
        my $gid=uc($1);
        $_=~/transcript_id "(.+?)"/;
        my $tid=$1;
        $class{$tid}="protein_coding";
        $g2t{$tid}=$gid;
        my $len=$field[4]-$field[3];
        $trans_len{$tid}=(exists $trans_len{$tid})?$trans_len{$tid}+$len:$len;
        $exon_num{$tid}=(exists $exon_num{$tid})?$exon_num{$tid}+1:1;
        }
        
        my %lin_class;
        open IN,"lncRNA_classification.txt" or die;                 #change the file name
        while(<IN>){
        chomp;
        my @data = split /\\t/,$_;
        $lin_class{$data[0]} = $data[1];
        }
        open FH,"lncRNA.final.CPAT.out" or die;
        
        <FH>;
        
        while(<FH>){
            chomp;
            my @field=split "\t";
            my $tid=uc($field[0]);
            my $class;
            if (defined($lin_class{$tid})){
                $class = $lin_class{$tid};
            }else{
                $class = 'NA';
            }
            print OUT $g2t{$tid}."\t".$tid."\t".$class{$tid}."\t".$field[5]."\t".$trans_len{$tid}."\t".$exon_num{$tid}."\t".$class."\n";
        }
            
        open FH,"protein_coding.final.CPAT.out" or die;
        
        <FH>;
                    
        while(<FH>){
            chomp;
            my @field=split "\t";
            my $tid=uc($field[0]);
            my $class;
            if (defined($lin_class{$tid})){
                $class = $lin_class{$tid};
            }else{
                $class = 'NA';
            }
            print OUT $g2t{$tid}."\t".$tid."\t".$class{$tid}."\t".$field[5]."\t".$trans_len{$tid}."\t".$exon_num{$tid}."\t".$class."\n";
         }

    '''
}

/*
*Step 11: Build kallisto index and perform quantification by kallisto
*/
process Build_kallisto_index_of_GTF_for_quantification {
    input:
    file transript_fasta from finalFasta_for_quantification_gtf

    output:
    file "transcripts.idx" into final_kallisto_index

    shell:
    '''
    #index kallisto reference 
    kallisto index -i transcripts.idx !{transript_fasta}
    
    '''
}

//Keep the chanel as constant variable to be used several times in quantification analysis
constant_kallisto_index = final_kallisto_index.first()

process Run_kallisto_for_quantification {


    tag { file_tag }

    input:
    file kallistoIndex from constant_kallisto_index
    set val(samplename), file(pair) from readPairs_for_kallisto

    output:
    file "${file_tag_new}_abundance.tsv" into kallisto_tcv_collection

    shell:
    file_tag = samplename
    file_tag_new = file_tag
    kallisto_threads = ava_cpu- 1
    if (params.singleEnd) {
        println print_purple("Quantification by kallisto in single end mode")
        if(params.qctools=="fastqc"){
            '''
        #quantification by kallisto in single end mode
        kallisto quant -i !{kallistoIndex} -o !{file_tag_new}_kallisto -t !{kallisto_threads} -b 100 --single -l 180 -s 20  <(zcat !{pair} ) 
        mv !{file_tag_new}_kallisto/abundance.tsv !{file_tag_new}_abundance.tsv
        '''
        }else {
            '''
        #quantification by kallisto in single end mode
        kallisto quant -i !{kallistoIndex} -o !{file_tag_new}_kallisto -t !{kallisto_threads} -b 100 --single -l 180 -s 20  !{pair} 
        mv !{file_tag_new}_kallisto/abundance.tsv !{file_tag_new}_abundance.tsv
        '''
        }

    } else {
        println print_purple("quantification by kallisto in paired end mode")
        if(params.qctools=="fastqc") {
            '''
        #quantification by kallisto 
        kallisto quant -i !{kallistoIndex} -o !{file_tag_new}_kallisto -t !{kallisto_threads} -b 100 <(zcat !{pair[0]} ) <(zcat !{pair[1]})
        mv !{file_tag_new}_kallisto/abundance.tsv !{file_tag_new}_abundance.tsv
        '''
        }else{
            '''
        #quantification by kallisto 
        kallisto quant -i !{kallistoIndex} -o !{file_tag_new}_kallisto -t !{kallisto_threads} -b 100 !{pair[0]} !{pair[1]}
        mv !{file_tag_new}_kallisto/abundance.tsv !{file_tag_new}_abundance.tsv
        '''
        }
    }
}

/*
*Step 12: Combine matrix for statistic  and differential expression analysis
*/

process Get_kallisto_matrix {
    tag { file_tag }
    publishDir pattern: "kallisto*.txt",
            path: "${params.out_folder}/Result/Quantification/", mode: 'copy'
    input:
    file abundance_tsv_matrix from kallisto_tcv_collection.collect()
    file annotated_gtf from finalGTF_for_annotate_gtf
    output:
    file "kallisto.count.txt" into expression_matrixfile_count
    file "kallisto.tpm.txt" into expression_matrixfile_tpm

    shell:
    file_tag = "Kallisto"
    '''
    grep -v "protein_coding"  final_all.gtf | awk -F '[\\t"]' '{print $12"\\t"$2}' | sort | uniq | cat - <(grep "protein_coding" final_all.gtf | awk -F '[\\t"]' '{print $12"\\t"$14}' | sort | uniq)> map.file
    R CMD BATCH !{baseDir}/bin/get_kallisto_matrix.R
    '''
}



/*
Step 13: perform Differential Expression analysis and generated reported
 */

// Initialize parameter for lncPipeReporter
lncRep_Output = params.lncRep_Output
lncRep_theme = params.lncRep_theme
lncRep_cdf_percent = params.lncRep_cdf_percent
lncRep_max_lnc_len = params.lncRep_max_lnc_len
lncRep_min_expressed_sample = params.lncRep_min_expressed_sample
design=null
if(params.design){
    design = file(params.design)
    if (!design.exists()) exit 1, "Design file not found, plz check your design path: ${params.design}"
}

process Run_LncPipeReporter {
    tag { file_tag }
    publishDir pattern: "*",
            path: "${params.out_folder}/Result/LncReporter", mode: 'mv'
    input:
    //alignmet log
    file design
    file alignmetlogs from alignment_logs.collect()
    //gtf statistics
    file basic_charac from statistic_result
    //Expression matrix
    file kallisto_count_matrix from expression_matrixfile_count

    output:
    file "LncPipeReports" into final_output
    shell:

    '''
    Rscript -e "library(LncPipeReporter);run_reporter(input='.', output = 'reporter.html',output_dir='./LncPipeReports',theme = 'npg',cdf.percent = 10,max.lncrna.len = 10000,min.expressed.sample = 50, ask = FALSE)"
  '''
}




