# space
if [ "$BOOTMODE" == true ]; then
  ui_print " "
fi

# magisk
if [ -d /sbin/.magisk ]; then
  MAGISKTMP=/sbin/.magisk
else
  MAGISKTMP=`realpath /dev/*/.magisk`
fi

# path
if [ "$BOOTMODE" == true ]; then
  MIRROR=$MAGISKTMP/mirror
else
  MIRROR=
fi
SYSTEM=`realpath $MIRROR/system`
PRODUCT=`realpath $MIRROR/product`
VENDOR=`realpath $MIRROR/vendor`
SYSTEM_EXT=`realpath $MIRROR/system/system_ext`
ODM=`realpath /odm`
MY_PRODUCT=`realpath /my_product`

# optionals
OPTIONALS=/sdcard/optionals.prop

# info
MODVER=`grep_prop version $MODPATH/module.prop`
MODVERCODE=`grep_prop versionCode $MODPATH/module.prop`
ui_print " ID=$MODID"
ui_print " Version=$MODVER"
ui_print " VersionCode=$MODVERCODE"
ui_print " MagiskVersion=$MAGISK_VER"
ui_print " MagiskVersionCode=$MAGISK_VER_CODE"
ui_print " "

# architecture
if [ "$ARCH" == arm64 ] || [ "$ARCH" == arm ]; then
  ui_print "- Architecture $ARCH"
  ui_print " "
else
  ui_print "! Unsupported architecture $ARCH. This module is only for"
  ui_print "  arm64 or arm architecture."
  abort
fi

# bit
if [ "$IS64BIT" != true ]; then
  rm -rf `find $MODPATH/system -type d -name *64`
fi

# sdk
NUM=30
NUM2=31
if [ "$API" -lt $NUM ]; then
  ui_print "! Unsupported SDK $API. You have to upgrade your Android"
  ui_print "  version at least SDK API $NUM to use this module."
  ui_print "  Use Moto Waves G 5G Plus instead!"
  abort
elif [ "$API" -gt $NUM2 ]; then
  ui_print "! Unsupported SDK $API. This module is only for SDK API"
  ui_print "  $NUM2 and bellow."
else
  ui_print "- SDK $API"
  if [ "$API" == $NUM2 ]\
  || [ "`grep_prop waves.mode $OPTIONALS`" == 12 ]; then
    if [ "`grep_prop waves.mode $OPTIONALS`" != 11 ]; then
      cp -rf $MODPATH/system_12/* $MODPATH/system
    fi
  fi
fi
ui_print " "
rm -rf $MODPATH/system_12

# mount
if [ "$BOOTMODE" != true ]; then
  mount -o rw -t auto /dev/block/bootdevice/by-name/cust /vendor
  mount -o rw -t auto /dev/block/bootdevice/by-name/vendor /vendor
  mount -o rw -t auto /dev/block/bootdevice/by-name/persist /persist
  mount -o rw -t auto /dev/block/bootdevice/by-name/metadata /metadata
fi

# sepolicy.rule
FILE=$MODPATH/sepolicy.sh
DES=$MODPATH/sepolicy.rule
if [ -f $FILE ] && [ "`grep_prop sepolicy.sh $OPTIONALS`" != 1 ]; then
  mv -f $FILE $DES
  sed -i 's/magiskpolicy --live "//g' $DES
  sed -i 's/"//g' $DES
fi

# .aml.sh
mv -f $MODPATH/aml.sh $MODPATH/.aml.sh

# check
NAME=_ZN7android23sp_report_stack_pointerEv
ui_print "- Checking $NAME function..."
ui_print "  Please wait..."
FILE=$SYSTEM/lib/libaudioclient.so
FILE2=$SYSTEM/lib/libutils.so
if ! grep -Eq $NAME $FILE || ! grep -Eq $NAME $FILE2; then
  ui_print "! Function not found. Use Moto Waves G 5G Plus instead!"
  abort
fi
ui_print " "

# config
if [ "`grep_prop waves.config $OPTIONALS`" == pstar ]; then
  ui_print "- Using Moto Waves Edge 30 Pro (pstar) config"
  cp -rf $MODPATH/system_pstar/* $MODPATH/system
  ui_print " "
elif [ "`grep_prop waves.config $OPTIONALS`" == nairo ]; then
  ui_print "- Using Moto Waves G 5G Plus (nairo) config"
  cp -rf $MODPATH/system_nairo/* $MODPATH/system
  ui_print " "
elif [ "`grep_prop waves.config $OPTIONALS`" == racer ]; then
  ui_print "- Using Moto Waves Edge (racer) config"
  cp -rf $MODPATH/system_racer/* $MODPATH/system
  ui_print " "
fi
rm -rf $MODPATH/system_pstar
rm -rf $MODPATH/system_nairo
rm -rf $MODPATH/system_racer

# mod ui
if [ "`grep_prop mod.ui $OPTIONALS`" == 1 ]; then
  APP=MotoWavesV2
  FILE=/sdcard/$APP.apk
  DIR=`find $MODPATH/system -type d -name $APP`
  ui_print "- Using modified UI apk..."
  if [ -f $FILE ]; then
    cp -f $FILE $DIR
    chmod 0644 $DIR/$APP.apk
    ui_print "  Applied"
  else
    ui_print "  ! There is no $FILE file."
    ui_print "    Please place the apk to your internal storage first"
    ui_print "    and reflash!"
  fi
  ui_print " "
fi

# function
extract_lib() {
for APPS in $APP; do
  ui_print "- Extracting..."
  FILE=`find $MODPATH/system -type f -name $APPS.apk`
  DIR=`find $MODPATH/system -type d -name $APPS`/lib/$ARCH
  mkdir -p $DIR
  rm -rf $TMPDIR/*
  unzip -d $TMPDIR -o $FILE $DES
  cp -f $TMPDIR/$DES $DIR
  ui_print " "
done
}

# extract
APP=MotoWavesV2
DES=lib/`getprop ro.product.cpu.abi`/*
extract_lib

# extract
APP=WavesServiceV2
ARCH=arm
DES=lib/armeabi-v7a/*
extract_lib

# cleaning
ui_print "- Cleaning..."
PKG="com.motorola.motowaves
     com.waves.maxxservice
     com.motorola.motosignature.app"
if [ "$BOOTMODE" == true ]; then
  for PKGS in $PKG; do
    RES=`pm uninstall $PKGS`
  done
fi
rm -rf /metadata/magisk/$MODID
rm -rf /mnt/vendor/persist/magisk/$MODID
rm -rf /persist/magisk/$MODID
rm -rf /data/unencrypted/magisk/$MODID
rm -rf /cache/magisk/$MODID
ui_print " "

# power save
FILE=$MODPATH/system/etc/sysconfig/*
if [ "`grep_prop power.save $OPTIONALS`" == 1 ]; then
  ui_print "- $MODNAME will not be allowed in power save."
  ui_print "  It may save your battery but decreasing $MODNAME performance."
  for PKGS in $PKG; do
    sed -i "s/<allow-in-power-save package=\"$PKGS\"\/>//g" $FILE
    sed -i "s/<allow-in-power-save package=\"$PKGS\" \/>//g" $FILE
  done
  ui_print " "
fi

# function
cleanup() {
if [ -f $DIR/uninstall.sh ]; then
  sh $DIR/uninstall.sh
fi
DIR=/data/adb/modules_update/$MODID
if [ -f $DIR/uninstall.sh ]; then
  sh $DIR/uninstall.sh
fi
}

# cleanup
DIR=/data/adb/modules/$MODID
FILE=$DIR/module.prop
if [ "`grep_prop data.cleanup $OPTIONALS`" == 1 ]; then
  sed -i 's/^data.cleanup=1/data.cleanup=0/' $OPTIONALS
  ui_print "- Cleaning-up $MODID data..."
  cleanup
  ui_print " "
elif [ -d $DIR ] && ! grep -Eq "$MODNAME" $FILE; then
  ui_print "- Different version detected"
  ui_print "  Cleaning-up $MODID data..."
  cleanup
  ui_print " "
fi

# function
permissive_2() {
sed -i '1i\
SELINUX=`getenforce`\
if [ "$SELINUX" == Enforcing ]; then\
  magiskpolicy --live "permissive *"\
fi\' $MODPATH/post-fs-data.sh
}
permissive() {
SELINUX=`getenforce`
if [ "$SELINUX" == Enforcing ]; then
  setenforce 0
  SELINUX=`getenforce`
  if [ "$SELINUX" == Enforcing ]; then
    ui_print "  Your device can't be turned to Permissive state."
    ui_print "  Using Magisk Permissive mode instead."
    permissive_2
  else
    setenforce 1
    sed -i '1i\
SELINUX=`getenforce`\
if [ "$SELINUX" == Enforcing ]; then\
  setenforce 0\
fi\' $MODPATH/post-fs-data.sh
  fi
fi
}

# permissive
if [ "`grep_prop permissive.mode $OPTIONALS`" == 1 ]; then
  ui_print "- Using device Permissive mode."
  rm -f $MODPATH/sepolicy.rule
  permissive
  ui_print " "
elif [ "`grep_prop permissive.mode $OPTIONALS`" == 2 ]; then
  ui_print "- Using Magisk Permissive mode."
  rm -f $MODPATH/sepolicy.rule
  permissive_2
  ui_print " "
fi

# function
hide_oat() {
for APPS in $APP; do
  mkdir -p `find $MODPATH/system -type d -name $APPS`/oat
  touch `find $MODPATH/system -type d -name $APPS`/oat/.replace
done
}
replace_dir() {
if [ -d $DIR ]; then
  mkdir -p $MODDIR
  touch $MODDIR/.replace
fi
}
hide_app() {
DIR=$SYSTEM/app/$APPS
MODDIR=$MODPATH/system/app/$APPS
replace_dir
DIR=$SYSTEM/priv-app/$APPS
MODDIR=$MODPATH/system/priv-app/$APPS
replace_dir
DIR=$PRODUCT/app/$APPS
MODDIR=$MODPATH/system/product/app/$APPS
replace_dir
DIR=$PRODUCT/priv-app/$APPS
MODDIR=$MODPATH/system/product/priv-app/$APPS
replace_dir
DIR=$MY_PRODUCT/app/$APPS
MODDIR=$MODPATH/system/product/app/$APPS
replace_dir
DIR=$MY_PRODUCT/priv-app/$APPS
MODDIR=$MODPATH/system/product/priv-app/$APPS
replace_dir
DIR=$PRODUCT/preinstall/$APPS
MODDIR=$MODPATH/system/product/preinstall/$APPS
replace_dir
DIR=$SYSTEM_EXT/app/$APPS
MODDIR=$MODPATH/system/system_ext/app/$APPS
replace_dir
DIR=$SYSTEM_EXT/priv-app/$APPS
MODDIR=$MODPATH/system/system_ext/priv-app/$APPS
replace_dir
DIR=$VENDOR/app/$APPS
MODDIR=$MODPATH/system/vendor/app/$APPS
replace_dir
DIR=$VENDOR/euclid/product/app/$APPS
MODDIR=$MODPATH/system/vendor/euclid/product/app/$APPS
replace_dir
}
check_app() {
if [ "$BOOTMODE" == true ]\
&& [ "`grep_prop hide.parts $OPTIONALS`" == 1 ]; then
  for APPS in $APP; do
    FILE=`find $SYSTEM $PRODUCT $SYSTEM_EXT $VENDOR\
               $MY_PRODUCT -type f -name $APPS.apk`
    if [ "$FILE" ]; then
      ui_print "  Checking $APPS.apk"
      ui_print "  Please wait..."
      if grep -Eq $UUID $FILE; then
        ui_print "  Your $APPS.apk will be hidden"
        hide_app
      fi
    fi
  done
fi
}
detect_soundfx() {
if [ "$BOOTMODE" == true ]\
&& dumpsys media.audio_flinger | grep -Eq $UUID; then
  ui_print "- $NAME is detected."
  ui_print "  It may be conflicting with this module."
  ui_print "  You can type:"
  ui_print "  disable.dirac=1"
  ui_print "  inside $OPTIONALS"
  ui_print "  and reinstall this module if you want to disable it."
  ui_print " "
fi
}

# hide
APP="`ls $MODPATH/system/priv-app` `ls $MODPATH/system/app`"
hide_oat
APP="MusicFX
     MotoWaves
     WavesService
     SoundAlive_80
     SoundAlive_70"
for APPS in $APP; do
  hide_app
done
if [ "`grep_prop disable.dirac $OPTIONALS`" == 1 ]\
&& [ "`grep_prop disable.misoundfx $OPTIONALS`" == 1 ]; then
  APP=MiSound
  for APPS in $APP; do
    hide_app
  done
fi
if [ "`grep_prop disable.dirac $OPTIONALS`" == 1 ]; then
  APP="Dirac DiracAudioControlService"
  for APPS in $APP; do
    hide_app
  done
fi

# dirac & misoundfx
FILE=$MODPATH/.aml.sh
APP="XiaomiParts ZenfoneParts ZenParts GalaxyParts
     KharaMeParts DeviceParts PocoParts"
NAME='dirac soundfx'
UUID=e069d9e0-8329-11df-9168-0002a5d5c51b
if [ "`grep_prop disable.dirac $OPTIONALS`" == 1 ]; then
  ui_print "- $NAME will be disabled"
  sed -i 's/#2//g' $FILE
  check_app
  ui_print " "
else
  detect_soundfx
fi
FILE=$MODPATH/.aml.sh
NAME=misoundfx
UUID=5b8e36a5-144a-4c38-b1d7-0002a5d5c51b
if [ "`grep_prop disable.misoundfx $OPTIONALS`" == 1 ]; then
  ui_print "- $NAME will be disabled"
  sed -i 's/#3//g' $FILE
  check_app
  ui_print " "
else
  if [ "$BOOTMODE" == true ]\
  && dumpsys media.audio_flinger | grep -Eq $UUID; then
    ui_print "- $NAME is detected."
    ui_print "  It may be conflicting with this module."
    ui_print "  You can type:"
    ui_print "  disable.misoundfx=1"
    ui_print "  inside $OPTIONALS"
    ui_print "  and reinstall this module if you want to disable it."
    ui_print " "
  fi
fi

# dirac_controller
FILE=$MODPATH/.aml.sh
NAME='dirac_controller soundfx'
UUID=b437f4de-da28-449b-9673-667f8b964304
if [ "`grep_prop disable.dirac $OPTIONALS`" == 1 ]; then
  ui_print "- $NAME will be disabled"
  ui_print " "
else
  detect_soundfx
fi

# dirac_music
FILE=$MODPATH/.aml.sh
NAME='dirac_music soundfx'
UUID=b437f4de-da28-449b-9673-667f8b9643fe
if [ "`grep_prop disable.dirac $OPTIONALS`" == 1 ]; then
  ui_print "- $NAME will be disabled"
  ui_print " "
else
  detect_soundfx
fi

# dirac_gef
FILE=$MODPATH/.aml.sh
NAME='dirac_gef soundfx'
UUID=3799D6D1-22C5-43C3-B3EC-D664CF8D2F0D
if [ "`grep_prop disable.dirac $OPTIONALS`" == 1 ]; then
  ui_print "- $NAME will be disabled"
  ui_print " "
else
  detect_soundfx
fi

# stream mode
FILE=$MODPATH/.aml.sh
PROP=`grep_prop stream.mode $OPTIONALS`
if echo "$PROP" | grep -Eq m; then
  ui_print "- Activating music stream..."
  sed -i 's/#m//g' $FILE
  sed -i 's/musicstream=/musicstream=true/g' $MODPATH/acdb.conf
  ui_print " "
else
  APP=AudioFX
  for APPS in $APP; do
    hide_app
  done
fi
if echo "$PROP" | grep -Eq r; then
  ui_print "- Activating ring stream..."
  sed -i 's/#r//g' $FILE
  ui_print " "
fi
if echo "$PROP" | grep -Eq a; then
  ui_print "- Activating alarm stream..."
  sed -i 's/#a//g' $FILE
  ui_print " "
fi
if echo "$PROP" | grep -Eq s; then
  ui_print "- Activating system stream..."
  sed -i 's/#s//g' $FILE
  ui_print " "
fi
if echo "$PROP" | grep -Eq v; then
  ui_print "- Activating voice_call stream..."
  sed -i 's/#v//g' $FILE
  ui_print " "
fi
if echo "$PROP" | grep -Eq n; then
  ui_print "- Activating notification stream..."
  sed -i 's/#n//g' $FILE
  ui_print " "
fi

# check
NAME=libadspd.so
APP=MotoWavesV2
DIR=`find $MODPATH/system -type d -name $APP`/lib/arm
cp -f $SYSTEM/lib/$NAME $DIR
cp -f $VENDOR/lib/$NAME $DIR
cp -f $ODM/lib/$NAME $DIR
if [ "$IS64BIT" == true ]; then
  DIR=`find $MODPATH/system -type d -name $APP`/lib/arm64
  cp -f $SYSTEM/lib64/$NAME $DIR
  cp -f $VENDOR/lib64/$NAME $DIR
  cp -f $ODM/lib64/$NAME $DIR
fi

# check
NAME=libc++_shared.so
for NAMES in $NAME; do
  FILE=$VENDOR/lib/$NAMES
  if [ -f $FILE ]; then
    ui_print "- Detected $NAMES"
    ui_print " "
    rm -f $MODPATH/system/vendor/lib/$NAMES
  fi
done

# audio rotation
FILE=$MODPATH/service.sh
if [ "`grep_prop audio.rotation $OPTIONALS`" == 1 ]; then
  ui_print "- Activating ro.audio.monitorRotation=true"
  sed -i '1i\
resetprop ro.audio.monitorRotation true' $FILE
  ui_print " "
fi

# raw
FILE=$MODPATH/.aml.sh
if [ "`grep_prop disable.raw $OPTIONALS`" == 0 ]; then
  ui_print "- Not disabling Ultra Low Latency playback (RAW)"
  ui_print " "
else
  sed -i 's/#u//g' $FILE
fi

# other
FILE=$MODPATH/service.sh
if [ "`grep_prop other.etc $OPTIONALS`" == 1 ]; then
  ui_print "- Activating other etc files bind mount..."
  sed -i 's/#p//g' $FILE
  ui_print " "
fi

# permission
ui_print "- Setting permission..."
DIR=`find $MODPATH/system/vendor -type d`
for DIRS in $DIR; do
  chown 0.2000 $DIRS
done
ui_print " "




