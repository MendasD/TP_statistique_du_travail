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
	global reptrav = "E:\Ecole\AS2\Semestre1\Stat du travail\TP"
	global dirdo = "$reptrav\dirdo"
	global dirdata = "$reptrav\dirdata"
	global diroutput = "$reptrav\diroutput"
	
	capture close
	log using "$diroutput\tp_final.smcl", replace
	
	cd "$dirdo" // repertoire de travail
	
/*******************************************************************************
    PART 2:  Préparation des données
********************************************************************************/
	
	// Ouverture de la base
	use using "E:\Ecole\AS2\Semestre1\Stat du travail\emploi.dta"
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
	
	
	
	
	log close
