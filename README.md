bioportal_web_ui
================

A rails application for biological ontologies, see http://bioportal.bioontology.org/

## Resolve problems

* Ca lag beaucoup sur des ontos avec beaucoup de submissions (comme TRANSMAT sur AgroPortal)

* Add New submission bug parfois (avec uploadFile) : faire des tests, s'il faut ça fait un moment que ça plante sans qu'on s'en rende compte (on utilise beaucoup l'URL en ce moment)
```ruby
TypeError (no implicit conversion of Symbol into Integer):
  app/controllers/submissions_controller.rb:28:in `[]'
  app/controllers/submissions_controller.rb:28:in `create'


# Following line bugs
if @errors[:error][:uploadFilePath] && @errors[:error][:uploadFilePath].first[:options]
end
```


