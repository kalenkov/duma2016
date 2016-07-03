#!/usr/bin/perl -w
use strict;
use warnings;

my $line;
my $okrug;
my $relations;
my @ids;
my $id;
my $all_source="";
my $all_land_source="";
my $osm_files="";
my $all_make="\trm -f okrug_all_diss.*\n";
my $all_land_make="\trm -f okrug_all_diss_land.*\n";
my $clean_source="";
my $clean_all_source="";

#Граница России
$id="60189";
print "$id.osm:\n";
print "\twget -O $id.osm \"http://www.openstreetmap.org/api/0.6/relation/$id/full\"\n";
$osm_files="$osm_files $id.osm";
print "russia.osm: $id.osm\n";
print "\tosmfilter $id.osm --drop-tags=\"name*=\" -o=russia.osm\n";
print "russia.shp: russia.osm\n";
print "\togr2ogr -f \"ESRI Shapefile\" russia.shp russia.osm --config OGR_SQLITE_SYNCHRONOUS OFF --config OSM_USE_CUSTOM_INDEXING NO -sql \"select osm_id from multipolygons where osm_id is not null\"\n";
print "russia_land.shp: russia.shp land_polygons.shp\n";
print "\togr2ogr -dialect SQLITE -sql \"SELECT ST_Intersection(A.geometry, B.geometry) AS geometry, A.*, B.* FROM land_polygons A, russia B WHERE ST_Intersects(A.geometry, B.geometry)\" . . -nln russia_land\n";
print "russia_land_diss.shp: russia_land.shp\n";
print "\togr2ogr russia_land_diss.shp russia_land.shp -dialect sqlite -sql \"SELECT ST_Union(geometry) AS geometry FROM russia_land\"\n";
print "clean_russia:\n";
print "\trm -f russia.osm russia.shp russia.shx russia.dbf russia.prj russia_land.shp russia_land.shx russia_land.dbf russia_land.prj russia_land_diss.shp russia_land_diss.shx russia_land_diss.dbf russia_land_diss.prj \n";
print "clean_all_russia: clean_russia\n";
print "\trm -f $id.osm\n\n";

#Синьяльское сельское поселение (5522997)
$id="5522997";
print "$id.osm:\n";
print "\twget -O $id.osm \"http://www.openstreetmap.org/api/0.6/relation/$id/full\"\n";
$osm_files="$osm_files $id.osm";
print "$id.shp: $id.osm\n";
print "\togr2ogr -f \"ESRI Shapefile\" $id.shp $id.osm --config OGR_SQLITE_SYNCHRONOUS OFF --config OSM_USE_CUSTOM_INDEXING NO -sql \"select osm_id from multipolygons where osm_id is not null\"\n";

print "sin.shp: sin.osm\n";
print "\togr2ogr -f \"ESRI Shapefile\" sin.shp sin.osm --config OGR_SQLITE_SYNCHRONOUS OFF --config OSM_USE_CUSTOM_INDEXING NO -sql \"select osm_id from multipolygons where osm_id is not null\"\n";
			
while (defined($line = <STDIN>)) {
	if($line =~ /(\d+)\t(.*)$/) {
		$okrug=$1;
		$relations=$2;
		$relations =~ s/\D+/ /g;
		$relations =~ s/^\s*//g;
		$relations =~ s/\s*$//g;
		@ids = split (/ /,$relations);
		my $shp_source="";
		my $shp_make="";
		my $clean="";
		my $clean_osm="";
		foreach $id (@ids) {
			print "$id.osm:\n";
			print "\twget -O $id.osm \"http://www.openstreetmap.org/api/0.6/relation/$id/full\"\n";
			$osm_files="$osm_files $id.osm";
			print "$id.shp: $id.osm\n";
			print "\togr2ogr -f \"ESRI Shapefile\" $id.shp $id.osm --config OGR_SQLITE_SYNCHRONOUS OFF --config OSM_USE_CUSTOM_INDEXING NO -sql \"select osm_id from multipolygons where osm_id is not null\"\n";
			$shp_source="$shp_source $id.shp";
			$shp_make="$shp_make\togr2ogr -update -append okrug_$okrug.shp $id.shp -nln okrug_$okrug\n";
			$clean="$clean $id.shp $id.shx $id.dbf $id.prj";
			$clean_osm="$clean_osm $id.osm";
		}
		#Синьяльское сельское поселение (5522997)
		$id="5522997";
		if($okrug==37) {
			print "$id\_$okrug.shp: sin.shp $id.shp\n";
			print "\togr2ogr -dialect SQLITE -sql \"SELECT ST_Intersection(A.geometry, B.geometry) AS geometry, A.*, B.* FROM sin A, '$id\' B WHERE ST_Intersects(A.geometry, B.geometry)\" . . -nln $id\_$okrug\n";
			$shp_source="$shp_source $id\_$okrug.shp";
			$shp_make="$shp_make\togr2ogr -update -append okrug_$okrug.shp $id\_$okrug.shp -nln okrug_$okrug\n";
			$clean="$clean $id.shp $id.shx $id.dbf $id.prj $id\_$okrug.shp $id\_$okrug.shx $id\_$okrug.dbf $id\_$okrug.prj sin.shp sin.shx sin.dbf sin.prj";
			$clean_osm="$clean_osm $id.osm";
		}
		if($okrug==38) {
			print "$id\_$okrug.shp: sin.shp $id.shp\n";
			print "\togr2ogr -dialect SQLITE -sql \"SELECT ST_Difference(A.geometry, B.geometry) AS geometry FROM '$id\' A, sin B WHERE A.geometry != B.geometry\" . . -nln $id\_$okrug\n";
			$shp_source="$shp_source $id\_$okrug.shp";
			$shp_make="$shp_make\togr2ogr -update -append okrug_$okrug.shp $id\_$okrug.shp -nln okrug_$okrug\n";
			$clean="$clean $id.shp $id.shx $id.dbf $id.prj $id\_$okrug.shp $id\_$okrug.shx $id\_$okrug.dbf $id\_$okrug.prj sin.shp sin.shx sin.dbf sin.prj";
			$clean_osm="$clean_osm $id.osm";
		}
		
		print "okrug_$okrug\_diss.shp: okrug_$okrug.shp\n";
		print "\togr2ogr okrug_$okrug\_diss.shp okrug_$okrug.shp -dialect sqlite -sql \"SELECT ST_Union(geometry) AS geometry FROM okrug_$okrug\"\n";
		print "\togrinfo okrug_$okrug\_diss.shp -sql \"ALTER TABLE okrug_$okrug\_diss ADD COLUMN okrug integer(4)\"\n";
		print "\togrinfo okrug_$okrug\_diss.shp -dialect SQLite -sql \"UPDATE okrug_$okrug\_diss SET okrug = $okrug\"\n";
		print "okrug_$okrug\_diss_land.shp: okrug_$okrug\_diss.shp russia_land_diss.shp\n";
		print "\togr2ogr -f \"ESRI Shapefile\" okrug_$okrug\_diss_land.shp -clipsrc russia_land_diss.shp okrug_$okrug\_diss.shp -nlt POLYGON -skipfailures\n";
		print "okrug_$okrug.shp: $shp_source\n";
		print "\trm -f okrug_$okrug.shp okrug_$okrug.shx okrug_$okrug.dbf okrug_$okrug.prj\n";
		print "$shp_make";
		print "clean_$okrug:\n";
		print "\t rm -f $clean okrug_$okrug.* okrug_$okrug\_diss.* okrug_$okrug\_diss_land.*\n";
		print "clean_all_$okrug: clean_$okrug\n";
		print "\t rm -f $clean_osm\n\n";
		
		$all_source="$all_source okrug_$okrug\_diss.shp";
		$all_land_source="$all_land_source okrug_$okrug\_diss_land.shp";
		$all_make="$all_make\togr2ogr -update -append okrug_all_diss.shp okrug_$okrug\_diss.shp -nln okrug_all_diss\n";
		$all_land_make="$all_land_make\togr2ogr -update -append okrug_all_diss_land.shp okrug_$okrug\_diss_land.shp -nln okrug_all_diss_land\n";
		$clean_source="$clean_source clean_$okrug";
		$clean_all_source="$clean_all_source clean_all_$okrug";
	}
}

print "osm_source: $osm_files\n";

print "okrug_all: $all_source\n";
print "$all_make \n";

print "okrug_all_land: $all_land_source\n";
print "$all_land_make \n";

print "clean_all_okrug: $clean_all_source\n\n";

print "clean_all: clean_all_okrug clean_all_russia\n\n";

print "clean_okrug: $clean_source\n\n";

print "clean: clean_okrug clean_russia\n\n";
