#/bin/sh
# Achtung! Dateien mit dem gleichen Namen aber an unterschiedlichen Orten werden
# als identisch betrachtet und miteinander synchronisiert! Wenn also irrtümlicherweise
# zwei unterschiedliche Dateien mit dem gleichen Namen in der Synchronisation auftauchen
# wird eine der beiden (die ältere) Dateien überschrieben.

# Hinweise zu den Dateilisten:
# - zu synchronisierende Ordner-Pfade müssen mit "/" enden!
# - immer absolute Pfade zu den Dateien angeben
# - Reihenfolge spielt keine Rolle
# - Kommentare mit '#' einleiten

WORKINGDIR=$(pwd)

if [ "$1" == "" ]; then
  echo "Usage: ./sync.sh flist"
  echo "Usage: ./sync.sh /Path/To/File/1 /Path/To/File/2 ..."
fi

# Liste und Speicherort der zu synchronisierenden Dateien einlesen
FILES=()
if [ "$2" == "" ]; then
  IFS=$'\r\n' command eval 'FILES=($(grep -v "^#" $1 | cut -f1 -d"#"))'
  unset IFS
else
  FILES=("$@")
fi

# speichere die Dateien im Arbeitsverzeichnis
mkdir -p $WORKINGDIR/SyncedFiles

# Backup der Vorgängerversion
rm -rf $WORKINGDIR/SyncedFiles_Backup
cp -r $WORKINGDIR/SyncedFiles $WORKINGDIR/SyncedFiles_Backup

# generiere Speicherort in $WORKINGDIR/SyncedFiles für die zu synchronisierenden Dateien
for f1 in "${FILES[@]}"; do
  if [ "${f1: -1}" == "/" ]; then
    NEW=$WORKINGDIR/SyncedFiles/$(basename $f1)/
  else
    NEW=$WORKINGDIR/SyncedFiles/$(basename $f1)
  fi
  #echo $NEW
  DONOTAPPEND=False
  for f2 in "${FILES[@]}"; do
    if [ $NEW == $f2 ]; then
      DONOTAPPEND=True
    fi
  done
  if [ "$DONOTAPPEND" != "True" ]; then
    FILES+=($NEW)
  fi
done

# Erstaufruf: Kopiere die Dateien und Ordner, falls am Zielort nicht vorhanden
for f1 in "${FILES[@]}"; do
  for f2 in "${FILES[@]}"; do
    # if file
    if [ "${f1: -1}" != "/" ] && [ $f1 != $f2 ] && [ $(basename $f1) == $(basename $f2) ] && [ -e $f1 ] && [ ! -e $f2 ]; then
      mkdir -p $(dirname $f2)
      cp -r $f1 $f2
    fi
    # if folder
    if [ "${f1: -1}" == "/" ] && [ $f1 != $f2 ] && [ $(basename $f1) == $(basename $f2) ] && [ -e $f1 ] && [ ! -e $f2 ]; then
      #echo "cp -r $f1 $f2"
      cp -r $f1 $f2
    fi
  done
done

# synchronisiere die Dateien untereinander
for f1 in "${FILES[@]}"; do
  for f2 in "${FILES[@]}"; do
    if [ $f1 != $f2 ] && [ $(basename $f1) == $(basename $f2) ]; then
      #echo "checking $f1 and $f2..."
      if ! diff -q $f1 $f2 &>/dev/null; then
        >&2 echo -e "> $f1\nand\n> $f2\ndiffer:"
        diff $f1 $f2
        if [ $f1 -nt $f2 ]; then
          echo -e "> $f1\nis newer than\n> $f2\nwill overwrite latter - is this ok [Y/n]?"
          read check
          if [ "$check" == "Y" ]; then
            rsync -avz --update $f1 $f2
          fi
        else
          echo -e "> $f2\nis newer than\n> $f1\nwill overwrite latter - is this ok [Y/n]?"
          read check
          if [ "$check" == "Y" ]; then
            rsync -avz --update $f2 $f1
          fi
        fi
      fi
    fi
  done
done 
