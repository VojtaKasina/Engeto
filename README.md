SQL projekt:
Datové poklady k porovnání mezd, základních potravin a jejich dostupnosti pro obyvatele ČR, HDP a nárůst cen potravin/mezd v čase, dodatečné datové podklady za ostatní státy (vhledy specificky pro EU a jejich srovnání s ČR).

Výstup projektu: 
A)	Tabulky
2 samostatné tabulky:
-	t_vojta_kasina_project_SQL_primary_final
-	t_vojta_kasina_project_SQL_secondary_final

-	2 pomocné tabulky (vztahující se k tab. t_vojta_kasina_project_SQL_primary_final)
o	t_vojta_kasina_salary_a_GDP
o	t_vojta_kasina_food

B)	Script: podkladová datová sada SQL dotazů se zodpovězením výzkumných otázek 
-	Script_vojta_kasina_project SQL_final


Výzkumné otázky a jejich zodpovězení:

1.	Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?
Odpověď: V období let 2006–2018 došlo občasným meziročním poklesům ve všech odvětvích (viz vizualizace zpracovaná na základě SQL scriptu v Tableau public zde: https://public.tableau.com/app/profile/vojtech.kasina/viz/Mezironprocentulnvvojmezdrstyapoklesydleodvtv/Dashboard_Mezironvvojmezd).

2.	Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období v dostupných datech cen a mezd?
Odpověď: Za první srov. období (r. 2006) bylo možno koupit za tehdejší průměrnou mzdu 1287 kg chleba nebo 1437 l mléka. Za poslední srov. období (r. 2018) bylo možno koupit za tehdejší průměrnou mzdu 1342 kg chleba nebo 1642 l mléka. Průměrné mzdy za sledovaná období (r. 2006 oproti r. 2018) tedy vzrostly rychleji než ceny vybraných potravin za stejné období.

3.	Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší procentuální meziroční nárůst)?
Odpověď: Z porovnání meziročních procentuálních rozdílů průměrných cen jednotlivých druhů potravin vyplývá, že za sledované období mezi lety 2006 a 2018 došlo k největšímu procentuálnímu poklesu ceny u Cukru krystalového (pokles ceny činil v úhrnu za všechny roky 21,76 %).

4.	Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)?
Odpověď: Ano, v roce 2013 byl nárůst cen potravin výrazně vyšší než nárůst mezd (cena potravin vzrostla o 8,5 % a mzdy poklesly o 2,05 %, rozdíl tedy v úhrnu činil 10,55 %).

5.	Má výška HDP vliv na změny ve mzdách a cenách potravin? Neboli, pokud HDP vzroste výrazněji v jednom roce, projeví se na to cenách potravin či mzdách ve stejném nebo následujícím roce výraznějším růstem?
Odpovědi: S ohledem na dostupná data dává smysl porovnání procent. rozdílů HDP, mezd a potravin v časovém úseku let 2007–2018. Z dostupných dat lze považovat za výrazný růst hodnot překračující 5% růst HDP za rok. V tomto ohledu byly významnými roky 2007, 2015 a 2017.
a)	Nárůst HDP za roky 2007, 2015 a 2018 se kladně projevuje i do růstu mezd v aktuálních i v bezprostředně následujících obdobích (následující rok). Trendově nelze potvrdit, že by významný (5%) nárůst HDP v jednom roce znamenal výraznější nárůst mezd v roce následujícím (např. za rok 2017 porostly mzdy více než v roce 2018).

b)	Nárůst HDP za roky 2007, 2015 a 2017 také koreluje s trendem cen potravin, avšak z dostupných dat lze říct, že trochu jiným způsobem než u mezd. Obecně platí, že při překročení 5% hranice růstu HDP rostly ceny potravin výrazněji v aktuálním roce, avšak výjimku tvoří rok 2015 (pokles cen potravin 0,55 %). Zde však nárůst cen potravin potvrdil rok navazující o 5,49 %.

Z výše uvedeného vyplývá, že významněji mezi sebou korelují růsty HDP a mezd oproti růstu cen potravin.

Dodatečná data o dalších státech jsou k dispozici v tabulce  t_vojta_kasina_project_SQL_secondary_final.

Pro příklad je k dispozici vytvořen script, který umožňuje srovnání procentuálního meziročního růstu HDP v EU  s HDP v ČR.
