#!/usr/bin/env bash
usage() { echo "$(basename $0) [-f tractoflow_input] [-c hcp] [-o output]" 1>&2; exit 1; }

while getopts "f:c:o:" args; do
    case "${args}" in
        f) f=${OPTARG};;
        c) c=${OPTARG};;
        o) o=${OPTARG};;
        *) usage;;
    esac
done
shift $((OPTIND-1))

if [ -z "${f}" ] || [ -z "${c}" ] || [ -z "${o}" ]; then
    usage
fi

TRACTOFLOWDIR=$(readlink -m ${f})
CIVETNFOUTDIR=$(readlink -m ${c})
OUTDIR=$(readlink -m ${o})

echo "Tractoflow previous input folder: ${TRACTOFLOWDIR}"
echo "Civet-nf results folder: ${CIVETNFOUTDIR}"
echo "Output folder: ${OUTDIR}"

echo "Building tree..."
cd ${TRACTOFLOWDIR}
for i in *;
do
    mkdir -p ${OUTDIR}/${i}

    # Tractoflow input
    for tfile in bval bvec dwi.nii.gz rev_b0.nii.gz;
    do
        if [ -f ${TRACTOFLOWDIR}/${i}/*${tfile} ]; then
            cp -L ${TRACTOFLOWDIR}/${i}/*${tfile}  ${OUTDIR}/${i}/${tfile}
        else
            echo "WARNING! ${tfile} was not found"
        fi
    done

    # CIVET input
    for cfile in t1.nii.gz brain_mask.nii.gz;
    do
        if [ -f ${CIVETNFOUTDIR}/${i}/*${cfile} ]; then
            cp -L ${CIVETNFOUTDIR}/${i}/*${cfile}  ${OUTDIR}/${i}/${cfile}
        else
            echo "WARNING! ${cfile} was not found"
        fi
    done

done
echo "Done"
