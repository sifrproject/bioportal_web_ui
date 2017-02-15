bioportal_web_ui
================

A rails application for biological ontologies, see http://bioportal.bioontology.org/

## Todo

### Finir les metadata (grosse prio)

* Permettre de filtrer les ontos en fct des metadata 
Voir col P : https://docs.google.com/spreadsheets/d/1r1twxJvXdQXrkX0Ocis6YY08nlO5cGneCAQ5F7U_CoA/edit#gid=0
Surtout dans les pages browse et welcome (voir les trucs en orange). Page Landscape plus tard

Le but c'est d'avoir des résultats visibles

* 3 blocks dans edit submission metadata
  * Origin
  * Toutes les prop qui ont la valeur S (colonne Q de docs.google Review of metadata prop) pour Simple
  * Toutes les prop qui ont la valeur C (colonne Q de docs.google Review of metadata prop) pour Complete

**SEPARER License, onto hasSyntax, etc. Des meatdata de base de NCBO**

**Change tout**
* Premier bloc avec les metadata pas du tout extraites (formats, contact, file upload...)
* 2eme bloc avec les metadata que le portal utilise: description, documentation...
* Expliquer que quand on ajoute un fichier les metadata sont updatés avec les metadata contenues dans le fichier (après le bloc des metadata non extraites)a

Add contact > même type de bouton que Add new Language (voir mail Clément)

Petit ? quand tu le survoles on dit qu'on extrait normalement cette metadata de l'onto à partir de: list des metadata mappings
Et on note "omv:description + rdfs:comment" quand on prend les valeurs de chaque propriété
Trouver comment montrer qu'on prend omv:naturalLanguage plusieurs fois si remplis plusieurs fois

Rassembler toutes les dates ensembles (au lieu de simple et complete) dans un même table

Attention date picker par défaut marche pas sur firefox (utiliser date picker de jQuery, celui used par NCBO)

Mettre des espaces : HASCONTRIBUTOR & cie

Afficher dans l'interface graphique quelle metadata on remplis par défaut (on les met toutes au même endroit ?)

On ne met pas 

TODO list : mettre un champ text plus gros ? (comme description)

Le but est d'éviter d'avoir un gros listing indigeste de metadata

Exemple :
Sous description ajouter bouton "voulez-vous ajouter un abstract?" 
Sous release date "voulez-vous ajouter d'autre dates"
Sous contact "voulez-vous ajouter d'autres peoples" ?
Sous publisher "voulez-vous ajouter d'autre rôle d'institut etc"

Depiction et logo à côté l'un de l'autre

Generalizes, HASDISJUNCTIONSWITH, et toutes les metadata de relations entre onto: faire en sorte de pouvoir choisir des ontos dans BioPortal (pitit popip)

Dans Default Properties sur le spreadsheet des metadata elles sont groupées


* Dans browse: permettre de trier dans l'ordre alphabétique
* Ajouter des petits drapeaux à côté des naturalLang (dans browse et dans la page de présentation des submissions)

* IncludedInDataCatalog: faudrait avoir des boutons plutôt (voir avec logo, pour les catalogs connus comme ontobee)



* Possibilité de saisir plusieurs lang

* Handling des metadata plus propre et

### Fermer les issues



### Page Welcome

https://github.com/sifrproject/bioportal_web_ui/issues/12
https://github.com/agroportal/agroportal_web_ui/issues/59


Dans links par exemple on peut mettre "need an ontology mapper: yamplusplus.lirmm.fr"

Feed twitter: https://support.twitter.com/articles/20170071
https://twitter.com/agrohackathon


## Resolve problems

* Ca lag beaucoup sur des ontos avec beaucoup de submissions (comme TRANSMAT sur AgroPortal)

* En particulier quand on ajoute une nouvelle submission

* Add New submission bug parfois (avec uploadFile) : faire des tests, s'il faut ça fait un moment que ça plante sans qu'on s'en rende compte (on utilise beaucoup l'URL en ce moment)
```ruby
TypeError (no implicit conversion of Symbol into Integer):
  app/controllers/submissions_controller.rb:28:in `[]'
  app/controllers/submissions_controller.rb:28:in `create'


# Following line bugs
if @errors[:error][:uploadFilePath] && @errors[:error][:uploadFilePath].first[:options]
end
```


## Log to production.log

```ruby
Rails.logger.warn "Submission params: #{params[:submission]}"
```
