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
gen total_inadequations =`total_inadequations'


* Calcul de l'effectif total
count
local effectif_total = r(N)

display "Effectif total : `effectif_total'"
gen effectif_total = `effectif_total'

* Calcul du taux d'inadéquation globale
gen taux_inadequation_globale = (total_inadequations / effectif_total) * 100

display "Le taux d'inadéquation globale est " taux_inadequation_globale "%" 

drop taux_inadequation_globale

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
		
	* Utilisation de l'approche microéconomique : méthode d'auto-évaluation des travailleurs
	* Les données proviennent d'une enquête sur l'emploi



	* Identifier les personnes en situation d'inadéquation
	
	* AP8A43 : Correspond-il à une formation antérieure ?
	* R2 : Pour quelle raison cherchez-vous un nouvel emploi ?
	* FPS6 : Auriez-vous besoin d'une formation spécifique afin d'améliorer vos prestations ou performances dans votre emploi ?

	* Identifier les personnes en situation d'inadéquation

* Inadéquation de qualification :
* R2 : Trouver un travail correspondant à sa qualification

// Evaluation de surqualification

* Créer une variable pour l'inadéquation liee a la surqualification
gen indice_globale_1 = 0
replace indice_globale_1= 1 if R2 == 3

* Définir les étiquettes pour la variable indice_de_surqualification
label define inadequation_labels_1 0 "Adéquation_1" 1 "Inadéquation_1"
label values indice_globale_1 inadequation_labels_1

* Validation des valeurs des variable indice_de _surqualification_*
tabulate indice_globale_1, missing

* Calcul du total des inadéquations_de surqualification*
summarize indice_globale_1
local total_inadequations_1 = r(sum)  // Extraction de la somme

display "Total des inadéquations_1 : `total_inadequations_1'"
gen total_inadequations_1 = `total_inadequations_1'
* Calcul de l'effectif total
count
local effectif_total_1 = r(N)

display "Effectif total_1 : `effectif_total_1'"
gen effectif_total_1 = `effectif_total_1'

* Calcul du taux de surqualification_*
gen taux_inadequation_globale_1 = (total_inadequations_1 / effectif_total_1) * 100

display "Le taux de surqualification est " taux_inadequation_globale_1 "%" 

// drop taux_inadequation_globale_1

// Calcul des indicateurs specifiques

* Calculer les taux de surqualification par sexe
gen taux_inadequation_sexe_1 = .
levelsof m3E, local(sexes)
foreach sexe in `sexes' {
    count if m3E == `sexe' & indice_globale_1 == 1
    local inad_sexe = r(N)
    count if m3E == `sexe'
    local total_sexe = r(N)
    replace taux_inadequation_sexe_1 = (`inad_sexe' / `total_sexe') * 100 if m3E == `sexe'
}

tabulate m3E taux_inadequation_sexe_1

display "Taux de surqualification par sexe calculé."

* Calculer les taux de surqualification par région
gen taux_inadequation_region_1 = .
levelsof Region, local(regions)
foreach region in `regions' {
    count if Region == `region' & indice_globale_1 == 1
    local inad_region = r(N)
    count if Region == `region'
    local total_region = r(N)
    replace taux_inadequation_region_1 = (`inad_region' / `total_region') * 100 if Region == `region'
}

tabulate Region taux_inadequation_region_1

display "Taux de surqualification par région calculé."

* Calculer les taux de surqualification par groupe d'âge
gen taux_inadequation_age_1 = .
levelsof groupe_age, local(ages)
foreach age in `ages' {
    count if groupe_age == `age' & indice_globale_1== 1
    local inad_age = r(N)
    count if groupe_age == `age'
    local total_age = r(N)
    replace taux_inadequation_age_1 = (`inad_age' / `total_age') * 100 if groupe_age == `age'
}

tabulate groupe_age taux_inadequation_age_1

display "Taux de surqualification par groupe d'âge calculé."

* Graphiques pour la présentation des résultats

* Répartition de l'indice de surqualification
graph pie, over(indice_globale_1) plabel(_all percent) ///
    title("Répartition de l'indice de surqualification") ///
    scheme(s2color)

* Répartition par sexe de la surqualification
graph bar (count), over(taux_inadequation_sexe_1) by(m3E, total) ///
    title("Répartition par sexe du taux d'inadéquation globale") ///
    scheme(s2color)

* Répartition par région de la surqualification
graph bar (count), over(Region) by(taux_inadequation_region_1, total) ///
    title("Répartition par région du taux de surqualification") ///
    scheme(s2color)

* Répartition par sexe et région de la surqualification
graph bar (count), over(Region, label(angle(45))) by(m3E, total) ///
    title("Répartition par sexe et région de la surqualification") ///
    scheme(s2color)

	* Distribution par groupe d'âge de la surqualification
graph bar (count), over(taux_inadequation_age_1) by(groupe_age, total) ///
    title("La distribution de la surqualification par groupe d'âge") ///
	scheme(s2color)
	
	
// Evaluation de sous-qualification

* Créer une variable pour l'inadéquation liee a la sous-qualification
gen indice_globale_2 = 0
* AP8A43 : Formation antérieure ne correspond pas
replace indice_globale_2 = 1 if AP8A43 == 2

* Définir les étiquettes pour la variable indice_globale_2
label define inadequation_labels_2 0 "Adéquation_2" 1 "Inadéquation_2"
label values indice_globale_2 inadequation_labels_2

* Validation des valeurs des variable indice_globale_2
tabulate indice_globale_2, missing

* Calcul du total des inadéquations_2
summarize indice_globale_2
local total_inadequations_2 = r(sum)  // Extraction de la somme

display "Total des inadéquations_2 : `total_inadequations_2'"
gen total_inadequations_2 = `total_inadequations_2'

* Calcul de l'effectif total
count
local effectif_total_2 = r(N)

display "Effectif total_2 : `effectif_total_2'"
gen effectif_total_2 = `effectif_total_2'

* Calcul du taux de sous-qualification
gen taux_inadequation_globale_2 = (total_inadequations_2 / effectif_total_2) * 100

display "Le taux de sous-qualification est " taux_inadequation_globale_2 "%" 

// drop taux_inadequation_globale_2

// Calcul des indicateurs specifiques

* Calculer les taux de sous-qualification par sexe
gen taux_inadequation_sexe_2 = .
levelsof m3E, local(sexes)
foreach sexe in `sexes' {
    count if m3E == `sexe' & indice_globale_2 == 1
    local inad_sexe = r(N)
    count if m3E == `sexe'
    local total_sexe = r(N)
    replace taux_inadequation_sexe_2 = (`inad_sexe' / `total_sexe') * 100 if m3E == `sexe'
}

tabulate m3E taux_inadequation_sexe_2

display "Taux d'inadéquation par sexe calculé."

* Calculer les taux de sous-qualification par région
gen taux_inadequation_region_2 = .
levelsof Region, local(regions)
foreach region in `regions' {
    count if Region == `region' & indice_globale_2 == 1
    local inad_region = r(N)
    count if Region == `region'
    local total_region = r(N)
    replace taux_inadequation_region_2= (`inad_region' / `total_region') * 100 if Region == `region'
}

tabulate Region taux_inadequation_region_2

display "Taux d'inadéquation par région calculé."

* Calculer les taux de sous-qualification par groupe d'âge
gen taux_inadequation_age_2= .
levelsof groupe_age, local(ages)
foreach age in `ages' {
    count if groupe_age == `age' & indice_globale_2 == 1
    local inad_age = r(N)
    count if groupe_age == `age'
    local total_age = r(N)
    replace taux_inadequation_age_2 = (`inad_age' / `total_age') * 100 if groupe_age == `age'
}

tabulate groupe_age taux_inadequation_age_2

display "Taux d'inadéquation par groupe d'âge calculé."

* Graphiques pour la présentation des résultats

* Répartition de l'indice globale
graph pie, over(indice_globale_2) plabel(_all percent) ///
    title("Répartition de l'indice de sous-qualification") ///
    scheme(s2color)

* Répartition par sexe de la sous-qualification
graph bar (count), over(taux_inadequation_sexe_2) by(m3E, total) ///
    title("Répartition par sexe du taux de sous-qualification") ///
    scheme(s2color)

* Répartition par région de la sous-qualification
graph bar (count), over(Region) by(taux_inadequation_region_2, total) ///
    title("Répartition par région du taux de sous-qualification") ///
    scheme(s2color)

* Répartition par sexe et région de la sous-qualification
graph bar (count), over(Region, label(angle(45))) by(m3E, total) ///
    title("Répartition par sexe et région de la sous-qualification") ///
    scheme(s2color)
	
	* Distribution par groupe d'âge de la sous-qualification
graph bar (count), over(taux_inadequation_age_2) by(groupe_age, total) ///
    title("La distribution de la sous-qualification par groupe d'âge") ///
	scheme(s2color)
	
	


* Inadéquation de compétences :

// Evaluation de la sous-competences

* Créer une variable pour l'inadéquation liee a la sous-competences
gen indice_globale_3 = 0
* FPS6 : Besoin d'une formation spécifique
replace indice_globale_3 = 1 if FPS6 == 1

* Définir les étiquettes pour la variable indice_globale
label define inadequation_labels_3 0 "Adéquation_3" 1 "Inadéquation_3"
label values indice_globale_3 inadequation_labels_3

* Validation des valeurs des variable indice_globale_*
tabulate indice_globale_3, missing

* Calcul du total des inadéquations_*
summarize indice_globale_3
local total_inadequations_3 = r(sum)  // Extraction de la somme

display "Total des inadéquations_3 : `total_inadequations_3'"
gen total_inadequations_3 = `total_inadequations_3'
* Calcul de l'effectif total
count
local effectif_total_3 = r(N)

display "Effectif total_3 : `effectif_total_3'"
gen effectif_total_3 = `effectif_total_3'

* Calcul du taux de sous-competences
gen taux_inadequation_globale_3 = (total_inadequations_3 / effectif_total_3) * 100

display "Le taux de sous-competences est " taux_inadequation_globale_3 "%" 

// drop taux_inadequation_globale_3

// Calcul des indicateurs specifiques

* Calculer les taux de sous-competences par sexe
gen taux_inadequation_sexe_3 = .
levelsof m3E, local(sexes)
foreach sexe in `sexes' {
    count if m3E == `sexe' & indice_globale_3 == 1
    local inad_sexe = r(N)
    count if m3E == `sexe'
    local total_sexe = r(N)
    replace taux_inadequation_sexe_3 = (`inad_sexe' / `total_sexe') * 100 if m3E == `sexe'
}

tabulate m3E taux_inadequation_sexe_3

display "Taux d'inadéquation par sexe calculé."

* Calculer les taux de sous-competences par région
gen taux_inadequation_region_3 = .
levelsof Region, local(regions)
foreach region in `regions' {
    count if Region == `region' & indice_globale_3 == 1
    local inad_region = r(N)
    count if Region == `region'
    local total_region = r(N)
    replace taux_inadequation_region_3 = (`inad_region' / `total_region') * 100 if Region == `region'
}

tabulate Region taux_inadequation_region_3

display "Taux d'inadéquation par région calculé."

* Calculer les taux de sous-competences par groupe d'âge
gen taux_inadequation_age_3 = .
levelsof groupe_age, local(ages)
foreach age in `ages' {
    count if groupe_age == `age' & indice_globale_3 == 1
    local inad_age = r(N)
    count if groupe_age == `age'
    local total_age = r(N)
    replace taux_inadequation_age_3 = (`inad_age' / `total_age') * 100 if groupe_age == `age'
}

tabulate groupe_age taux_inadequation_age_3

display "Taux d'inadéquation par groupe d'âge calculé."

* Graphiques pour la présentation des résultats

* Répartition de l'indice globale_3
graph pie, over(indice_globale_3) plabel(_all percent) ///
    title("Répartition de l'indice de la sous-competence") ///
    scheme(s2color)

* Répartition par sexe de sous-competences
graph bar (count), over(taux_inadequation_sexe_3) by(m3E, total) ///
    title("Répartition par sexe du taux de sous-competences") ///
    scheme(s2color)

* Répartition par région de la sous-competence
graph bar (count), over(Region) by(taux_inadequation_region_3, total) ///
    title("Répartition par région du taux de sous-competences") ///
    scheme(s2color)

* Répartition par sexe et région de la sous-competences
graph bar (count), over(Region, label(angle(45))) by(m3E, total) ///
    title("Répartition par sexe et région de la sous-competence") ///
    scheme(s2color)
	
	* Distribution par groupe d'âge de la sous-competence
graph bar (count), over(taux_inadequation_age_3) by(groupe_age, total) ///
    title("La distribution de la sous-competence par groupe d'âge") ///
	scheme(s2color)
	
	
log close
