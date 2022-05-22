#ALTERAR rsync!!!

mkdir 001_mol2_files
mkdir 002_dock_outputs
mkdir 003_g09_runs
mkdir 004_charges_calculation
mkdir 005_topologies
cd 005_topologies 
mkdir 001_files
cd ..
mkdir 006_MMGBSA_rescoring

rsync -av /data/homes/joelsantos13/Tese_Mestrado/006_docking_GOLD/001_Ligands/Sertaconazole.mol2 001_mol2_files
rsync -av /data/homes/joelsantos13/Tese_Mestrado/006_docking_GOLD/001_Ligands/Fluspirilene.mol2 001_mol2_files
rsync -av /data/homes/joelsantos13/Tese_Mestrado/005_docking_autodock_vina/AutoDock_Vina_v1.2.3/AutoDock4_Runs/998_Different_Charge_Methods_test/001_script/001_files/Sertaconazole_test/Sertaconazole_out.pdbqt 002_dock_outputs  #ALTERAR!!!
rsync -av /data/homes/joelsantos13/Tese_Mestrado/005_docking_autodock_vina/AutoDock_Vina_v1.2.3/AutoDock4_Runs/998_Different_Charge_Methods_test/001_script/001_files/Fluspirilene_test/Fluspirilene_out.pdbqt 002_dock_outputs   #ALTERAR!!!
rsync -av 002_dock_outputs/Sertaconazole_out.pdbqt 005_topologies/001_files   
rsync -av 002_dock_outputs/Fluspirilene_out.pdbqt 005_topologies/001_files

for dock_out in $(find -name "*_out.pdbqt");
do
PREFIX=$(echo ${dock_out} | sed "s/_out.pdbqt//g" | sed "s/^.*\///g")
DIR="005_topologies/${PREFIX}"
   mkdir -p $DIR
   cp ${dock_out} $DIR
done

for dock_out in $(find -name "*_out.pdbqt" -not -path "./005_topologies/001_files/*" -not -path "./002_dock_outputs/*");
do
PDB=$(echo ${dock_out} | sed "s/_out.pdbqt//g" | sed "s/^.*\///g")
	obabel $dock_out -m -O $PDB.pdb; 
done

for PDB in $(find -name "*[0-9]*.pdb" -not -path "./005_topologies/001_files/*" -not -path "./002_dock_outputs/*");
do 
PDB_obb=$(echo ${PDB} | sed "s/.pdb//g" | sed "s/^.*\///g");  
PREFIX=$(echo $PDB_obb | sed "s/[0-9]*//g")
DIR="005_topologies/${PREFIX}/${PDB_obb}"
	mkdir -p $DIR 
	mv ${PDB_obb}.pdb $DIR
done

for PDB in $(find -name "*[0-9]*.pdb" -not -path "./005_topologies/001_files/*" -not -path "./002_dock_outputs/*");
do  
PDB_obb=$(echo ${PDB} | sed "s/.pdb//g" | sed "s/^.*\///g");
PREFIX=$(echo $PDB_obb | sed "s/[0-9]*//g")
DIR="005_topologies/${PREFIX}/${PDB_obb}"         
	pdb4amber ${PDB} > ${PDB_obb}_to_pose.pdb
done

for PDB in *_to_pose.pdb
do
PDB_obb=$(echo ${PDB} | sed "s/_to_pose.pdb//g" | sed "s/^.*\///g");
PREFIX=$(echo $PDB_obb | sed "s/[0-9]*//g")
DIR="005_topologies/${PREFIX}/${PDB_obb}"         
	mv ${PDB_obb}_to_pose.pdb $DIR
	rm -f stdout_nonprot.pdb stdout_renum.txt stdout_sslink
done

for PDB in $(find -name "*[0-9]*_to_pose.pdb" -not -path "./005_topologies/001_files/*" -not -path "./002_dock_outputs/*");
do 
PDB_obb=$(echo ${PDB} | sed "s/_to_pose.pdb//g" | sed "s/^.*\///g");  
PREFIX=$(echo $PDB_obb | sed "s/[0-9]*//g")
DIR="005_topologies/${PREFIX}/${PDB_obb}"
	rsync -av /data/homes/joelsantos13/Tese_Mestrado/003_LilrB2_Ben_MD/topologies/lilrb2_protonated_ben_clo.pdb $DIR
	grep "CL" $DIR/lilrb2_protonated_ben_clo.pdb > $DIR/CL_CL.pdb
	sed -e "/BEN/d" -e "/CL/d" $DIR/lilrb2_protonated_ben_clo.pdb > $DIR/lilrb2_protonated.pdb
	cat $DIR/lilrb2_protonated.pdb $DIR/${PDB_obb}_to_pose.pdb $DIR/CL_CL.pdb > $DIR/lilrb2_protonated_${PDB_obb}_clo.pdb
	pdb4amber $DIR/lilrb2_protonated_${PDB_obb}_clo.pdb > $DIR/lilrb2_protonated_${PDB_obb}_clo_fix.pdb 
	rm -f stdout_nonprot.pdb stdout_renum.txt stdout_sslink
done

for MOL2 in $(find -name "*.mol2");
do
PREFIX=$(echo ${MOL2} | sed "s/.mol2//g" | sed "s/^.*\///g")
DIR="003_g09_runs/${PREFIX}"
   mkdir -p $DIR
   cp ${MOL2} $DIR
done

for MOL2 in $(find -name "*.mol2" -not -path "./001_mol2_files/*");
do
PREFIX=$(echo ${MOL2} | sed "s/.mol2//g" | sed "s/^.*\///g")
DIR="003_g09_runs/${PREFIX}"
	antechamber -i ${MOL2} -fi mol2 -o $DIR/${PREFIX}.am1.gjc -fo gcrt -ch "${PREFIX}.am1.chk" -gm "%mem=24GB" -gn "%nproc=24"  -gk "#p AM1 opt"; 
done

for GJC in $(find -name "*.am1.gjc" -not -path "./001_mol2_files/*");
do
PREFIX=$(echo ${GJC} | sed "s/.am1.gjc//g" | sed "s/^.*\///g")
DIR="004_charges_calculation/${PREFIX}"
   mkdir -p $DIR
   cp ${GJC} $DIR
done

for GJC in $(find -name "*.am1.gjc" -not -path "./001_mol2_files/*" -not -path "./003_g09_runs/*");
do
PREFIX=$(echo ${GJC} | sed "s/.am1.gjc//g" | sed "s/^.*\///g")
DIR="004_charges_calculation/${PREFIX}"
	antechamber -o $DIR/${PREFIX}.mol2 -fo mol2 -i ${GJC} -fi gcrt -c bcc -at gaff2 
	rm -f ATOMTYPE.INF ANTECHAMBER_AC.AC ANTECHAMBER_BOND_TYPE.AC0 sqm.out ANTECHAMBER_BOND_TYPE.AC ANTECHAMBER_AC.AC0 sqm.in sqm.pdb ANTECHAMBER_AM1BCC_PRE.AC ANTECHAMBER_AM1BCC.AC
done

for PDB in $(find -name "*[0-9]*_to_pose.pdb" -not -path "./005_topologies/001_files/*" -not -path "./002_dock_outputs/*");
do
PDB_obb=$(echo ${PDB} | sed "s/_to_pose.pdb//g" | sed "s/^.*\///g");  
PREFIX=$(echo $PDB_obb | sed "s/[0-9]*//g")
DIR1="004_charges_calculation/${PREFIX}"
DIR2="005_topologies/${PREFIX}/${PDB_obb}"
	cp $DIR1/$PREFIX.mol2 $DIR2
done

for PDB in $(find -name "*[0-9]*_to_pose.pdb" -not -path "./005_topologies/001_files/*" -not -path "./002_dock_outputs/*");
do
PDB_obb=$(echo ${PDB} | sed "s/_to_pose.pdb//g" | sed "s/^.*\///g");  
PREFIX=$(echo $PDB_obb | sed "s/[0-9]*//g")
DIR="005_topologies/${PREFIX}/${PDB_obb}"
parmchk2 -i $DIR/${PREFIX}.mol2 -f mol2 -s 2 -o $DIR/${PREFIX}.frcmod
rm -f 
done

for PDB in $(find -name "*[0-9]*_to_pose.pdb" -not -path "./005_topologies/001_files/*" -not -path "./002_dock_outputs/*");
do
PDB_obb=$(echo ${PDB} | sed "s/_to_pose.pdb//g" | sed "s/^.*\///g");  
PREFIX=$(echo $PDB_obb | sed "s/[0-9]*//g")
DIR="005_topologies/${PREFIX}/${PDB_obb}"
cat << EOF > tleap.in
logfile leap.log

source leaprc.protein.ff14SB

source leaprc.water.tip3p

frcmod.ionsjc_tip3p = loadamberparams /data/programs/amber20_src/dat/leap/parm/frcmod.ionsjc_tip3p

source leaprc.gaff2

loadamberparams 005_topologies/${PREFIX}/${PDB_obb}/${PREFIX}.frcmod
MOL = loadmol2 005_topologies/${PREFIX}/${PDB_obb}/${PREFIX}.mol2
check MOL

lilrb2 = loadpdb 005_topologies/${PREFIX}/${PDB_obb}/lilrb2_protonated_${PDB_obb}_clo_fix.pdb
check lilrb2

#bond lilrb2.25.SG lilrb2.74.SG
#bond lilrb2.132.SG lilrb2.142.SG
#bond lilrb2.120.SG lilrb2.172.SG

check lilrb2
saveoff lilrb2 005_topologies/${PREFIX}/${PDB_obb}/lilrb2_protonated_${PDB_obb}_clo.lib
saveamberparm lilrb2 005_topologies/${PREFIX}/${PDB_obb}/lilrb2_protonated_${PDB_obb}_clo.top 005_topologies/${PREFIX}/${PDB_obb}/lilrb2_protonated_${PDB_obb}_clo.crd

lilrb2_oct = copy lilrb2
solvateoct lilrb2_oct TIP3PBOX 14 iso
saveoff lilrb2_oct 005_topologies/${PREFIX}/${PDB_obb}/lilrb2_protonated_${PDB_obb}_clo_oct.lib
saveamberparm lilrb2_oct 005_topologies/${PREFIX}/${PDB_obb}/lilrb2_protonated_${PDB_obb}_clo_oct.top 005_topologies/${PREFIX}/${PDB_obb}/lilrb2_protonated_${PDB_obb}_clo_oct.crd

quit
EOF
	cp tleap.in $DIR
	tleap -f $DIR/tleap.in  > $DIR/tleap.log
done

for PDB in $(find -name "*[0-9]*_to_pose.pdb" -not -path "./005_topologies/001_files/*" -not -path "./002_dock_outputs/*");
do
PDB_obb=$(echo ${PDB} | sed "s/_to_pose.pdb//g" | sed "s/^.*\///g");  
PREFIX=$(echo $PDB_obb | sed "s/[0-9]*//g")
DIR="005_topologies/${PREFIX}/${PDB_obb}"
	ambpdb -p $DIR/lilrb2_protonated_${PDB_obb}_clo.top -c $DIR/lilrb2_protonated_${PDB_obb}_clo.crd > $DIR/lilrb2_protonated_${PDB_obb}_clo_tleap.pdb
	ambpdb -p $DIR/lilrb2_protonated_${PDB_obb}_clo_oct.top -c $DIR/lilrb2_protonated_${PDB_obb}_clo_oct.crd > $DIR/lilrb2_protonated_${PDB_obb}_clo_oct.pdb
done

for PDB in $(find -name "*[0-9]*_to_pose.pdb" -not -path "./005_topologies/001_files/*" -not -path "./002_dock_outputs/*");
do
PDB_obb=$(echo ${PDB} | sed "s/_to_pose.pdb//g" | sed "s/^.*\///g");  
PREFIX=$(echo $PDB_obb | sed "s/[0-9]*//g")
DIR="005_topologies/${PREFIX}/${PDB_obb}"
cat << EOF > parmed.in
parm $DIR/lilrb2_protonated_${PDB_obb}_clo.top
summary
checkValidity
writeFrcmod $DIR/lilrb2_protonated_${PDB_obb}_clo_oct.ff
quit
EOF
	cp parmed.in $DIR
	parmed -i $DIR/parmed.in
done

for PDB in $(find -name "*[0-9]*_to_pose.pdb" -not -path "./005_topologies/001_files/*" -not -path "./002_dock_outputs/*");
do
PDB_obb=$(echo ${PDB} | sed "s/_to_pose.pdb//g" | sed "s/^.*\///g");  
PREFIX=$(echo $PDB_obb | sed "s/[0-9]*//g")
DIR="006_MMGBSA_rescoring/${PREFIX}/${PDB_obb}"
   mkdir -p $DIR
done

for PDB in $(find -name "*[0-9]*_to_pose.pdb" -not -path "./005_topologies/001_files/*" -not -path "./002_dock_outputs/*");
do
PDB_obb=$(echo ${PDB} | sed "s/_to_pose.pdb//g" | sed "s/^.*\///g");  
PREFIX=$(echo $PDB_obb | sed "s/[0-9]*//g")
DIR1="006_MMGBSA_rescoring/${PREFIX}/${PDB_obb}"
DIR2="005_topologies/${PREFIX}/${PDB_obb}"
cat << EOF > parmed_LIG.in
parm $DIR2/lilrb2_protonated_${PDB_obb}_clo_oct.top
strip !:197 nobox
outparm $DIR1/lilrb2_${PDB_obb}_lig.top
quit
EOF
	cp parmed_LIG.in $DIR1
	parmed -i $DIR1/parmed_LIG.in
done
for PDB in $(find -name "*[0-9]*_to_pose.pdb" -not -path "./005_topologies/001_files/*" -not -path "./002_dock_outputs/*");
do
PDB_obb=$(echo ${PDB} | sed "s/_to_pose.pdb//g" | sed "s/^.*\///g");  
PREFIX=$(echo $PDB_obb | sed "s/[0-9]*//g")
DIR1="006_MMGBSA_rescoring/${PREFIX}/${PDB_obb}"
DIR2="005_topologies/${PREFIX}/${PDB_obb}"
cat << EOF > parmed_REC.in
parm $DIR2/lilrb2_protonated_${PDB_obb}_clo_oct.top
strip :1-196 nobox
summary
outparm $DIR1/lilrb2_${PDB_obb}_rec.top
quit
EOF
	cp parmed_REC.in $DIR1
	parmed -i $DIR1/parmed_REC.in
done
for PDB in $(find -name "*[0-9]*_to_pose.pdb" -not -path "./005_topologies/001_files/*" -not -path "./002_dock_outputs/*");
do
PDB_obb=$(echo ${PDB} | sed "s/_to_pose.pdb//g" | sed "s/^.*\///g");  
PREFIX=$(echo $PDB_obb | sed "s/[0-9]*//g")
DIR1="006_MMGBSA_rescoring/${PREFIX}/${PDB_obb}"
DIR2="005_topologies/${PREFIX}/${PDB_obb}"
cat << EOF > parmed_COM.in
parm $DIR2/lilrb2_protonated_${PDB_obb}_clo_oct.top
strip :1-197 nobox
summary
outparm $DIR1/lilrb2_${PDB_obb}_com.top
quit
EOF
	cp parmed_COM.in $DIR1
	parmed -i $DIR1/parmed_COM.in
done

