# Skript to generate a customize Ubuntu image
# 
# Adapt script_to_run_in_chroot.sh and run this after the chroot.
#
# 8 GB are required
#
# Inspired by https://help.ubuntu.com/community/LiveCDCustomization
#
# by Konrad Förstner <konrad@foerstner.org>
# 

main(){
    RELEASE=14.04
    PLATFORM=amd64
    IMAGE_URL=http://de.releases.ubuntu.com/${RELEASE}/ubuntu-${RELEASE}-desktop-amd64.iso
    MODIFIED_IMAGE_NAME="Trusty Tahr READemption version"
    ROOT_FOLDER=~/live_system_tmp
    MNT_FOLDER=${ROOT_FOLDER}/mnt
    EXTRACT_FOLDER=${ROOT_FOLDER}/extract-cd
    EDIT_FOLDER=${ROOT_FOLDER}/edit
    ISO_VERSION_SUFFIX=READemption

    create_folders
    downlaod_image
    mount_image
    extract_image
    extract_desktop_system
    inject_script
    prepare_and_chroot
    umount_dev
    assemble_the_file_system
    generate_iso
}

create_folders(){
    for FOLDER in ${ROOT_FOLDER} ${MNT_FOLDER} ${EXTRACT_FOLDER} ${EDIT_FOLDER}
    do
	mkdir ${FOLDER}
    done

}

downlaod_image(){
    wget -cP ${ROOT_FOLDER} ${IMAGE_URL}
}

mount_image(){
    sudo mount -o loop ${ROOT_FOLDER}/ubuntu-${RELEASE}-desktop-${PLATFORM}.iso ${MNT_FOLDER}
}

extract_image(){
    sudo rsync --exclude=/casper/filesystem.squashfs -a ${MNT_FOLDER}/ ${EXTRACT_FOLDER}
}

extract_desktop_system(){
    cd ${ROOT_FOLDER} && \
	sudo unsquashfs $MNT_FOLDER/casper/filesystem.squashfs && \
	sudo mv squashfs-root/* ${EDIT_FOLDER}
     # original sudo mv squashfs-root/* ${EDIT_FOLDER} # which is wrong!
}

inject_script(){
    sudo cp script_to_run_in_chroot.sh $EDIT_FOLDER/root/
}

prepare_and_chroot(){
    sudo cp /etc/resolv.conf ${EDIT_FOLDER}/etc/
    sudo cp /etc/hosts ${EDIT_FOLDER}/etc/
    sudo mount --bind /dev/ ${EDIT_FOLDER}/dev
    echo "================================="
    echo "WILL NOW PERFORM CHROOT!"
    echo "Run the script in /root yourself."
    echo "Call 'exit' when you are done."
    echo "================================="
    sudo chroot ${EDIT_FOLDER}
    mount -t proc none /proc
    mount -t sysfs none /sys
    mount -t devpts none /dev/pts
}

umount_dev(){
    sudo umount $EDIT_FOLDER/dev
}

assemble_the_file_system(){
    sudo chmod a+w ${EXTRACT_FOLDER}/casper/filesystem.manifest
    sudo chroot ${EDIT_FOLDER} dpkg-query -W --showformat='${Package} ${Version}\n' > ${EXTRACT_FOLDER}/casper/filesystem.manifest
    sudo cp ${EXTRACT_FOLDER}/casper/filesystem.manifest ${EXTRACT_FOLDER}/casper/filesystem.manifest-desktop
    sudo sed -i '/ubiquity/d' ${EXTRACT_FOLDER}/casper/filesystem.manifest-desktop
    sudo sed -i '/casper/d' ${EXTRACT_FOLDER}/casper/filesystem.manifest-desktop

    sudo rm ${EXTRACT_FOLDER}/casper/filesystem.squashfs
    sudo mksquashfs ${EDIT_FOLDER} ${EXTRACT_FOLDER}/casper/filesystem.squashfs
    printf $(sudo du -sx --block-size=1 ${EDIT_FOLDER} | cut -f1) > size
    sudo mv size ${EXTRACT_FOLDER}/casper/filesystem.size

    # CAN: add an image name in extract-cd/README.diskdefines 
    ## sudo vim extract-cd/README.diskdefines
    cd ${EXTRACT_FOLDER} && \
	sudo rm md5sum.txt && find -type f -print0 | \
	sudo xargs -0 md5sum | \
	grep -v isolinux/boot.cat | \
	sudo tee md5sum.txt \
	&& cd -
}

generate_iso(){
    cd ${EXTRACT_FOLDER} && \
	sudo mkisofs \
	-D \
	-r \
	-V "${MODIFIED_IMAGE_NAME}" \
	-cache-inodes \
	-J \
	-l \
	-b isolinux/isolinux.bin \
	-c isolinux/boot.cat \
	-no-emul-boot \
	-boot-load-size 4 \
	-boot-info-table -o \
	../ubuntu-${RELEASE}-desktop-${PLATFORM}-${ISO_VERSION_SUFFIX}.iso . && \
	cd -

    sudo umount /home/kuf/live_system_tmp/mnt
}

main
