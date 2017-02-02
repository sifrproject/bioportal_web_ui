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
