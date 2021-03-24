#!/usr/bin/env nextflow
params.civet = false
params.help = false

if(params.help) {
    usage = file("$baseDir/USAGE")

    engine = new groovy.text.SimpleTemplateEngine()

    bindings = ["processes": "$params.processes",
                "output_dir": "$params.output_dir"]

    template = engine.createTemplate(usage.text).make(bindings)

    print template.toString()
    return
}

log.info "SET nextflow pipeline for CIVET"
log.info "==============================================="
log.info ""
log.info "Start time: $workflow.start"
log.info ""


workflow.onComplete {
    log.info "Pipeline completed at: $workflow.complete"
    log.info "Execution status: ${ workflow.success ? 'OK' : 'failed' }"
    log.info "Execution duration: $workflow.duration"
}

if (params.civet) {
    log.info "Input Civet: $params.civet"


    civet = file(params.civet)
    in_civet_transfo = Channel
        .fromFilePairs("$civet/*/transforms/linear/*t1_tal.xfm",
                        size: 1,
                        maxDepth:5,
                        flat: true) {it.parent.parent.parent.name}
    in_civet_animal = Channel
        .fromFilePairs("$civet/*/segment/*animal_labels.mnc",
                        size: 1,
                        maxDepth:5,
                        flat: true) {it.parent.parent.name}
    in_civet_native = Channel
        .fromFilePairs("$civet/*/native/*t1.mnc",
                        size: 1,
                        maxDepth:5,
                        flat: true) {it.parent.parent.name}
    in_civet_pve = Channel
        .fromFilePairs("$civet/*/{classify/*pve_exactcsf.mnc,classify/*pve_exactgm.mnc,classify/*pve_exactsc.mnc,classify/*pve_exactwm.mnc,final/*t1_final.mnc,mask/*brain_mask.mnc}",
                        size: 6,
                        maxDepth:5,
                        flat: true) {it.parent.parent.name}

    in_civet_animal
        .join(in_civet_native)
        .join(in_civet_pve)
        .join(in_civet_transfo)
        .set{in_civet}


    process Register_civet_to_T1 {
        cpus 1

        input:
        set sid, file(animal_labels), file(t1_native), file(pve_csf), file(pve_gm), file(pve_sc), file(pve_wm), file(t1), file(brain_mask), file(xfm_transfo) from in_civet

        output:
        file "${sid}__t1.nii.gz"
        file "${sid}__t1_native.nii.gz"
        file "${sid}__labels.nii.gz"
        file "${sid}__pve_csf.nii.gz"
        file "${sid}__pve_gm.nii.gz"
        file "${sid}__pve_sc.nii.gz"
        file "${sid}__pve_wm.nii.gz"
        file "${sid}__brain_mask.nii.gz"

        script:
        """
        mnc2nii $t1_native ${sid}__t1_native.nii
        scil_resample_volume.py  ${sid}__t1_native.nii ${sid}__t1_native_iso05.nii --resolution 0.5 --interp lin
        nii2mnc ${sid}__t1_native_iso05.nii ${sid}__t1_native_iso05.mnc
        gzip ${sid}__t1_native.nii

        mincresample $t1 ${sid}__temp.mnc -trilinear -spacetype 2 -invert_transformation -transformation $xfm_transfo -clobber -like ${sid}__t1_native_iso05.mnc
        mnc2nii ${sid}__temp.mnc ${sid}__t1.nii
        gzip ${sid}__t1.nii

        mincresample $animal_labels ${sid}__temp.mnc -nearest_neighbour -spacetype 2 -invert_transformation -transformation $xfm_transfo -clobber -like ${sid}__t1_native_iso05.mnc
        mnc2nii ${sid}__temp.mnc ${sid}__labels.nii
        gzip ${sid}__labels.nii

        mincresample $brain_mask ${sid}__temp.mnc -nearest_neighbour -spacetype 2 -invert_transformation -transformation $xfm_transfo -clobber -like ${sid}__t1_native_iso05.mnc
        mnc2nii ${sid}__temp.mnc ${sid}__brain_mask.nii
        gzip ${sid}__brain_mask.nii

        mincresample $pve_csf ${sid}__temp.mnc -trilinear -spacetype 2 -invert_transformation -transformation $xfm_transfo -clobber -like ${sid}__t1_native_iso05.mnc
        mnc2nii ${sid}__temp.mnc ${sid}__pve_csf.nii
        gzip ${sid}__pve_csf.nii

        mincresample $pve_gm ${sid}__temp.mnc -trilinear -spacetype 2 -invert_transformation -transformation $xfm_transfo -clobber -like ${sid}__t1_native_iso05.mnc
        mnc2nii ${sid}__temp.mnc ${sid}__pve_gm.nii
        gzip ${sid}__pve_gm.nii

        mincresample $pve_sc ${sid}__temp.mnc -trilinear -spacetype 2 -invert_transformation -transformation $xfm_transfo -clobber -like ${sid}__t1_native_iso05.mnc
        mnc2nii ${sid}__temp.mnc ${sid}__pve_sc.nii
        gzip ${sid}__pve_sc.nii

        mincresample $pve_wm ${sid}__temp.mnc -trilinear -spacetype 2 -invert_transformation -transformation $xfm_transfo -clobber -like ${sid}__t1_native_iso05.mnc
        mnc2nii ${sid}__temp.mnc ${sid}__pve_wm.nii
        gzip ${sid}__pve_wm.nii
        """
    }
}
