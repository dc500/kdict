DATE=$(date +"%Y-%m-%d")
TMPDIR=/tmp
OUTDIR=$1
BINDIR=$2

# temporary locations
json_file=kdict-$DATE.json
csv_file=kdict-$DATE.csv

$BINDIR/mongoexport -d kdict -c entries -o $TMPDIR/$json_file
$BINDIR/mongoexport --csv -d kdict -c entries -f korean.hangul,definitions.english,hanja,pos,flags,old.wordid,old.table -o $TMPDIR/$csv_file

# make tar
tar -zcvf $OUTDIR/kdict-$DATE-json.tar -C $TMPDIR/ $json_file
tar -zcvf $OUTDIR/kdict-$DATE-csv.tar  -C $TMPDIR/ $csv_file

rm $TMPDIR/$json_file
rm $TMPDIR/$csv_file

