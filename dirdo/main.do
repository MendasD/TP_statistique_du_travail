/*******************************************************************************
*                          TP STATISTIQES DU TRAVAIL                           *
********************************************************************************
*                                                                              *
*   THEME 4 : ANALYSE COMPARATIVE DES NIVEAUX D'INADEQUATION DE COMPETENCES    *
*			  ENTRE JEUNES HOMMES ET JEUNES FEMMES EN EMPLOI                   *
*			                                                                   *                                                                         
*                                                                              *
*   PLAN:     PART 1:  Préparation de l'environnement de travail               *
*		      PART 2:  Préparation des données                                 *
*             PART 3:  Caractéristiques des personnes en emploi 			   *
*             PART 4:  Calculs des indicateurs d'inadéquation des compétences  *			                                             		 
*                     et comparaison des indicateurs chez les hommes et femmes *
*                                                                              *
********************************************************************************
    PART 1:  Préparation de l'environnement de travail
********************************************************************************/
	
	capture clear // Vider la mémoire
	set dp comma // Définir le point comme séparateur de milliers
	set more off // Afficher les résultats complets
	
	** Fixation des répertoires de travail **
	global reptrav = "C:\Users\Ibrahima\Documents\GitHub\TP_statistique_du_travail"
	capture close
	log using "$reptrav\diroutput\tp_final.smcl", replace
	
	cd "C:\Users\Ibrahima\Documents\GitHub\TP_statistique_du_travail\dirdo" 
// 	repertoire de travail
	
/*******************************************************************************
    PART 2:  Préparation des données
********************************************************************************/
	
	// Ouverture de la base
	use using "C:\Users\Ibrahima\Documents\GitHub\TP_statistique_du_travail\dirdata\emploi.dta"
	describe

/*******************************************************************************
    PART 3:  Caractéristiques des personnes en emploi
********************************************************************************/
	
	// Âge de travail
	gen c_age_travail = cond(m4>=15&m4<65,1,0)
	la var c_age_travail "Âge de travail"
	
	// On conserve uniquement les individus en âge de travailler
	keep if c_age_travail != 0 
	
	** Identification des personnes en emploi : Employé, indépendant, employeur, 
	**App & Stag rémunérés, Aides familiaux 
	
	gen Emp = cond(SE2==1,1,0)
	
	// Reconstitution de SE3
	gen SE3b = 0
	foreach point of varlist SE3_1-SE3_9{
		gen `point'_b = `point'
		// On remplace le 2 (Non) par 0
		replace `point'_b=cond(`point'_b==2,0,`point'_b)
		replace SE3b=SE3b + `point'_b
	}
	
	// On supprime les variables dichotomiques crées
	drop SE3_*_b
	
	// Récupérer ceux qui ont effectué certaines activités et qui en réalité 
	// pensent ne pas avoir travaillé pour une rémunération
	
	replace Emp = cond(SE3b!=0&Emp==0,1,Emp)
	
	// Recupérer ceux qui ont un emploi rémunéré et qui ne l'ont pas exercé 
	// au cours des 7 derniers pour des raisons temporaires
	gen recup = cond(SE4==1&(SE5<=4),1,0)
	replace recup=cond(SE4==1&(SE5==5|SE5==7|SE5==9)&SE6A==1, 1, recup)
	replace recup = cond(SE4==1&(SE5==6&SE6B==1),1,recup)
	
	// On ajoute les personnes récupérées dans l'emploi
	replace Emp = cond(Emp==0&recup==1,1,Emp)
	
	// On retient les personnes qui sont en emploi
	keep if Emp == 1
	la var Emp "En emploi"
	
	** Caractéristiques socio-démographiques **
	
	// Répartition par sexe
	tabulate m3E
	graph pie, over(m3E) plabel(_all percent) ///
    title("Répartition par sexe") 
	
	// Répartition par groupe d'âge
	gen groupe_age = cond(m4<25,1,cond(m4<35,2,cond(m4<45,3,cond(m4<55,4,5))))
	label define groupe_age_label 1 "15-24" 2 "25-34" 3 "35-44" 4 "45-54" 5 "55-64"
	label values groupe_age groupe_age_label
	
	tabulate groupe_age
	
	// Répartition suivant la région
	label define region 1 "Dakar" 2 "Diourbel" 3 "Fatick" 4 "Kaffrine" ///
	5 "Kaolack" 6 "Kedougou" 7 "Kolda" 8 "Louga" 9 "Matam" 10 "Saint-Louis" ///
	11 "Sédhiou" 12 "Tambacounda" 13 "Thiès" 14 "Ziguinchor" , replace

	label values Region region
	
	tabulate Region
	graph hbar (count), over(Region, label(angle(0))) ///
    title("Répartition par régions") ///
	
	// Répartition suivant la catégorie socio-professionnelle
	tabulate AP3
	
	// En fonction du type de lieu où l'emploi est exercé
	tabulate AP7
	
	// Façon dont la personne a obtenu l'emploi
	tabulate AP8B
	
	// Sexe et région
	tabulate m3E Region, row col
	
	// sexe et âge
	tabulate m3E groupe_age, row col
	graph bar (count), over(groupe_age) by(m3E) 
	
/*******************************************************************************
    PART 4:  Calculs des indicateurs de l'inadéquation
********************************************************************************/
	
	* Utilisation de l'approche microéconomique : méthode d'auto-évaluation des travailleurs
	* Les données proviennent d'une enquête sur l'emploi

	* Créer une variable pour l'inadéquation globale
	gen indice_globale = 0

	* Identifier les personnes en situation d'inadéquation
	
	* AP8A43 : Correspond-il à une formation antérieure ?
	* R2 : Pour quelle raison cherchez-vous un nouvel emploi ?
	* FPS6 : Auriez-vous besoin d'une formation spécifique afin d'améliorer vos prestations ou performances dans votre emploi ?

	* Identifier les personnes en situation d'inadéquation

* Inadéquation de qualification :
* R2 : Trouver un travail correspondant à sa qualification
replace indice_globale = 1 if R2 == 3

* AP8A43 : Formation antérieure ne correspond pas
replace indice_globale = 1 if AP8A43 == 2

* Inadéquation de compétences :
* FPS6 : Besoin d'une formation spécifique
replace indice_globale = 1 if FPS6 == 1

* Définir les étiquettes pour la variable indice_globale
label define inadequation_labels 0 "Adéquation" 1 "Inadéquation"
label values indice_globale inadequation_labels

* Validation des valeurs de la variable indice_globale
tabulate indice_globale, missing

* Calcul du total des inadéquations
summarize indice_globale
local total_inadequations = r(sum)  // Extraction de la somme

display "Total des inadéquations : `total_inadequations'"
gen total_inadequations = `total_inadequations'


* Calcul de l'effectif total
count
local effectif_total = r(N)

display "Effectif total : `effectif_total'"
gen effectif_total = `effectif_total'

* Calcul du taux d'inadéquation globale
gen taux_inadequation_globale = (total_inadequations / effectif_total) * 100

display "Le taux d'inadéquation globale est " taux_inadequation_globale "%" 

// drop taux_inadequation_globale

// Calcul des indicateurs specifiques

* Calculer les taux d'inadéquation par sexe
gen taux_inadequation_sexe = .
levelsof m3E, local(sexes)
foreach sexe in `sexes' {
    count if m3E == `sexe' & indice_globale == 1
    local inad_sexe = r(N)
    count if m3E == `sexe'
    local total_sexe = r(N)
    replace taux_inadequation_sexe = (`inad_sexe' / `total_sexe') * 100 if m3E == `sexe'
}

tabulate m3E taux_inadequation_sexe

display "Taux d'inadéquation par sexe calculé."

* Calculer les taux d'inadéquation par région
gen taux_inadequation_region = .
levelsof Region, local(regions)
foreach region in `regions' {
    count if Region == `region' & indice_globale == 1
    local inad_region = r(N)
    count if Region == `region'
    local total_region = r(N)
    replace taux_inadequation_region = (`inad_region' / `total_region') * 100 if Region == `region'
}

tabulate Region taux_inadequation_region

display "Taux d'inadéquation par région calculé."

* Calculer les taux d'inadéquation par groupe d'âge
gen taux_inadequation_age = .
levelsof groupe_age, local(ages)
foreach age in `ages' {
    count if groupe_age == `age' & indice_globale == 1
    local inad_age = r(N)
    count if groupe_age == `age'
    local total_age = r(N)
    replace taux_inadequation_age = (`inad_age' / `total_age') * 100 if groupe_age == `age'
}

tabulate groupe_age taux_inadequation_age

display "Taux d'inadéquation par groupe d'âge calculé."

* Graphiques pour la présentation des résultats

* Répartition de l'indice globale
graph pie, over(indice_globale) plabel(_all percent) ///
    title("Répartition de l'indice globale") ///
    scheme(s2color)

* Répartition par sexe de inadéquation globale
graph bar (count), over(taux_inadequation_sexe) by(m3E, total) ///
    title("Répartition par sexe du taux d'inadéquation globale") ///
    scheme(s2color)

* Répartition par région de l'inadéquation globale
graph bar (count), over(Region) by(taux_inadequation_region, total) ///
    title("Répartition par région du taux d'inadéquation globale") ///
    scheme(s2color)

* Répartition par sexe et région de l'inadéquation globale
graph bar (count), over(Region, label(angle(45))) by(m3E, total) ///
    title("Répartition par sexe et région de l'inadéquation globale") ///
    scheme(s2color)
	
	* Distribution par groupe d'âge
graph bar (count), over(taux_inadequation_age) by(groupe_age, total) ///
    title("La distribution de l'inadequation globale par groupe d'âge") ///
	scheme(s2color)
    

	
	
	
	
	
	
        ** Analyse statistique comparative **
		
//Inadequation de competences

gen non_adeq_comp=" " if AP8A41==1 & AP8A42==1 & FPS1==1 & FPS6==1

// Repartition selon le sexe

sort m3E
by m3E: tabulate non_adeq_comp

// Graphe representant la repartition par sexe


graph pie, over(m3E non_adeq_comp) plabel(_all percent) title("Repartition du taux d'inadequation de competences par sexe") 

//Repartition selon les zones geographiques


graph hbar (count), over(non_adeq_comp, label(angle(0))) by(m3E Region,col(1)) ytitle("Répartition des niveaux d'inadéquation des compétences par sexe suivant les regions")

//Inadequation horizontale et verticale

//Inadequation de qualifications


gen non_adeq_qual=" " if R1==1 & R2==3

// Repartition selon le sexe

sort m3E
by m3E: tabulate non_adeq_qual

// Graphe representant la repartition par sexe

graph pie, over(m3E non_adeq_qual) plabel(_all percent) title("Repartition du taux d'inadequation de qualifications par sexe") 

//Repartition selon les zones geographiques

graph hbar (count), over(non_adeq_qual, label(angle(0))) by(m3E Region,col(1)) ytitle("Répartition des niveaux d'inadéquation des qualifications par sexe suivant les regions")

//Inadequation spatiale


label define Zone_industriel_label 1 "Dakar" 13 "Thiès" 5 "Kaolack"///
10 "Saint-Louis" 14 "Zinguinchor" 12 "Tambacounda" 2 "Diourbel"///
,replace
label values Zone_industriel Zone_industriel_label





log close
