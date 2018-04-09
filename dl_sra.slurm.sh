#!/bin/bash
#-------------------------------------------------------------------------------
#  SBATCH CONFIG
#-------------------------------------------------------------------------------
## resources
#SBATCH --partition Lewis  # for jobs < 2hrs try 'General'
#SBATCH --nodes=1
#SBATCH --ntasks=1  # used for MPI codes, otherwise leave at '1'
#SBATCH --cpus-per-task=1 # cores per task
#SBATCH --mem-per-cpu=8G  # memory per core (default is 1GB/core)
#SBATCH --time 2-00:00  # days-hours:minutes
#SBATCH --qos=normal
#SBATCH --account=general  # investors will replace this with their account name
#
## labels and outputs
#SBATCH --job-name=sra_dl
#SBATCH --output=results-%j.out  # %j is the unique jobID
#
## notifications
#SBATCH --mail-user=buckleyrm@missouri.edu  # email address for notifications
#SBATCH --mail-type=BEGIN,END,FAIL  # which type of notifications to send
#
## array options
#
#-------------------------------------------------------------------------------

### NOTES

# invoke with RUN_SHEET=<sra run sheet with header> sbatch --array=2-$(wc -l < <sra run sheet with header>) dl_sra.sh

# set tmp dir for sra caching before starting, otherwise home will fill up and kill task
#TMP=$(pwd)
#mkdir -p $TMP/.tmp_ncbi
#echo "/repository/user/main/public/root = \"$TMP/.tmp_ncbi\"" > $HOME/.ncbi/user-settings.mkfg

# load module before begining
# module load sratoolkit/sratoolkit-2.8.1-2

#-------------------------------------------------------------------------------

echo "### Starting at: $(date) ###"

# random sleep time so runs don't collide
sleep $((RANDOM % 5))

# read sample name
ROW=$SLURM_ARRAY_TASK_ID
SM=$(cut -f 20 $RUN_SHEET | sed "${ROW}q;d")



# create dir unless it already exists
if [ -d $SM ]
then
	echo "$SM dir exists, continuing"
else
	echo "$SM dir does not exist, creating"
	mkdir $SM
fi

# get library name
LIB=$(cut -f 11 $RUN_SHEET | sed "${ROW}q;d")

# get run name
RUN=$(cut -f 17 $RUN_SHEET | sed "${ROW}q;d")

echo -e "\nbegin fastq dump on sample $SM, library $LIB, srr $RUN \n"


# pull fastq RUN and store in ./sm/lib/
fastq-dump --split-files --origfmt --gzip --outdir ./$SM/$LIB $RUN

echo -e "\nfastq dump complete, renaming srr from $RUN to $LIB"
mv ./$SM/$LIB/${RUN}_1.fastq.gz ./$SM/$LIB/${LIB}_1.fastq.gz
mv ./$SM/$LIB/${RUN}_2.fastq.gz ./$SM/$LIB/${LIB}_2.fastq.gz

echo -e "\nunzip read 1"
gunzip ./$SM/$LIB/${LIB}_1.fastq.gz
echo unzip done, split into runs
split_library_by_run ./$SM/$LIB/${LIB}_1.fastq
echo split done, rm original
rm ./$SM/$LIB/${LIB}_1.fastq
echo zip new run fastq files
gzip ./$SM/$LIB/${LIB}*_1.fastq

echo -e "\nunzip read 2"
gunzip ./$SM/$LIB/${LIB}_2.fastq.gz
echo unzip done, split into runs
split_library_by_run ./$SM/$LIB/${LIB}_2.fastq
echo split done, rm original
rm ./$SM/$LIB/${LIB}_2.fastq
echo zip new fun fastq files
gzip ./$SM/$LIB/${LIB}*_2.fastq


echo "### Ending at: $(date) ###" #!/bin/bash
