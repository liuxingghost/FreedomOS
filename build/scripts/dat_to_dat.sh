#!/bin/bash
# FreedomOS build script
# Author : Nevax
# Contributors : TimVNL, Mavy

#aboot -x boot.img
#tools/abootimg-unpack-initrd initrd.img
#get filecontext

#sdat2img.py system.transfer.list system.new.dat system.img
#mount -t ext4 -o loop system.img output/
#make_ext4fs -T 0 -S file_contexts -l ${SYSTEMIMAGE_PARTITION_SIZE} -a system system_new.img output/
#rimg2sdat system_new.img

function dat_to_dat {
  # Building Process
  echo "> $device build starting now with $BUILD_METHOD build method." 2>&1 | tee -a ${build_log}

  echo ">> Copying ${ROM_NAME} needed files" 2>&1 | tee -a ${build_log}
  rsync -vr ${rom_root}/${device}/${ROM_NAME}/* ${tmp_root}/ --exclude='system.transfer.list' --exclude='system.new.dat' --exclude='system.patch.dat' --exclude='META-INF/' >> ${build_log} 2>&1
  mkdir -p ${tmp_root}/mount >> ${build_log} 2>&1
  mkdir -p ${tmp_root}/system >> ${build_log} 2>&1

  mkdir -p ${tmp_root}/boot
  cp ${tmp_root}/boot.img ${tmp_root}/boot/boot.img
  cd ${tmp_root}/boot
  echo ">> Getting kernel informations" 2>&1 | tee -a ${build_log}
  ${build_root}/tools/abootimg -i boot.img >> ${build_log} 2>&1
  echo ">>> Extracting kernel" 2>&1 | tee -a ${build_log}
  ${build_root}/tools/abootimg -x boot.img >> ${build_log} 2>&1
  echo ">>> Extracting ramdisk" 2>&1 | tee -a ${build_log}
  ${build_root}/tools/abootimg-unpack-initrd initrd.img >> ${build_log} 2>&1
  echo ">>> Copy needed files" 2>&1 | tee -a ${build_log}
  cp ${tmp_root}/boot/ramdisk/file_contexts ${tmp_root}/

  cd ${tmp_root}
  echo ">> Extracting system.new.dat" 2>&1 | tee -a ${build_log}
  ${build_root}/tools/sdat2img.py ${rom_root}/${device}/${ROM_NAME}/system.transfer.list ${rom_root}/${device}/${ROM_NAME}/system.new.dat ${tmp_root}/system.img >> ${build_log} 2>&1

  echo ">> Mounting ext4 system.img" 2>&1 | tee -a ${build_log}
  mount -t ext4 -o loop ${tmp_root}/system.img ${tmp_root}/mount/ >> ${build_log} 2>&1

  echo ">>> Removing unneeded system files" 2>&1 | tee -a ${build_log}
  for i in ${CLEAN_LIST}
  do
    rm -rvf ${tmp_root}/mount/${i} >> ${build_log} 2>&1
  done

  echo ">>> Patching system files" 2>&1 | tee -a ${build_log}
  cp -rvf ${assets_root}/system/${ARCH}/* ${tmp_root}/mount >> ${build_log} 2>&1

  echo ">> Building new ext4 system" 2>&1 | tee -a ${build_log}
  ${build_root}/tools/make_ext4fs -T 0 -S file_contexts -l ${SYSTEMIMAGE_PARTITION_SIZE} -a system system_new.img mount/ >> ${build_log} 2>&1

  echo ">> Converting ext4 to dat file" 2>&1 | tee -a ${build_log}
  ${build_root}/tools/rimg2sdat system_new.img >> ${build_log} 2>&1

  echo "> Clean unneeded tmp files" 2>&1 | tee -a ${build_log}
  if mount | grep "${tmp_root}/mount" > /dev/null;
  then
    echo ">> Unmount rom" 2>&1 | tee -a ${build_log}
    umount ${tmp_root}/mount/ >> ${build_log} 2>&1
  fi
  echo ">> Deleting files" 2>&1 | tee -a ${build_log}
  rm -rvf ${tmp_root}/mount >> ${build_log} 2>&1
  rm -rvf ${tmp_root}/system.img >> ${build_log} 2>&1
  rm -rvf ${tmp_root}/system_new.img >> ${build_log} 2>&1
  rm -rvf ${tmp_root}/file_contexts >> ${build_log} 2>&1
  rm -rvf ${tmp_root}/boot >> ${build_log} 2>&1
  rm -rvf ${tmp_root}/system >> ${build_log} 2>&1
}