require "date"
require "net/http"
require 'xml'
require "rexml/document"
require 'open-uri'
require 'uri'
require 'cgi'

class BioPortalRestfulCore
  
  #Resources
#    BASE_URL="http://ncbo-core-dev1:8080/bioportal/rest"
    BASE_URL=$REST_URL
    #BASE_URL="http://rest.bioontology.org/bioportal/rest"
    #BASE_URL="http://ncbo-core-stage1.stanford.edu/bioportal/rest"
    
    ONTOLOGIES_PATH = "/ontologies/%ONT%"
    CATEGORIES_PATH = "/categories/"

    CONCEPT_PATH ="/concepts/%ONT%/?conceptid=%CONC%"
    PATH_PATH = "/path/%ONT%/?source=%CONC%&target=root"
    VERSIONS_PATH="/ontologies/versions/%ONT%"
    
    METRICS_PATH = "/ontologies/metrics/%ONT%"
    
    VIEW_PATH = "/ontologies/%VIEW%"
#    VIEW_CONCEPT_PATH = "/concepts/view/%VIEW%/?conceptid=%CONC%"
    VIEW_CONCEPT_PATH = "/concepts/%VIEW%/?conceptid=%CONC%"
    VIEW_VERSIONS_PATH = "/views/versions/%ONT%"
#    http://ncbo-core-dev1.stanford.edu/bioportal/rest/search/cell?includeproperties=1&ontologyids=1070,%201032&pagesize=50&pagenum=2&isexactmatch=0
    SEARCH_PATH="/search/%query%?%ONT%"
    PROPERTY_SEARCH_PATH="/search/properties/%query%?ontologies=%ONT%"
    VIRTUAL_URI_PATH="/virtual/ontology/%ONT%/%CONC%"
    META_SEARCH_PATH="/search/meta/%query%"
    USERS_PATH="/users"
    USER_PATH = "/users/%USR%"
    AUTH_PATH = "/auth"
    PARSE_ONTOLOGY = "/ontologies/parse/%ONT%"
    PARSE_BATCH = "/ontologies/parsebatch/%START%/%END%"
    
    DIFFS_PATH="/diffs/%ONT%"
    DOWNLOAD_DIFF="/diffs/download/%VER1%/%VER2%"
    
  #Constants
    SUPERCLASS="SuperClass"
    SUBCLASS="SubClass"
    CHILDCOUNT="ChildCount"
    APPLICATION_ID = "4ea81d74-8960-4525-810b-fa1baab576ff"
    
    # Track paths that have already been processed when building a path to root tree 
    @seen_paths = {}
    
 
#    OBO
#    2861
#    20845
#    3231
#    2991
#    2996

#    OWL
#    3905
#    13386
#    6723
#    3205
#    4525
 
      
      def self.getView(view_id)
        view = nil
#        begin
          
          doc = REXML::Document.new(open(BASE_URL + VIEW_PATH.gsub("%VIEW%",view_id)+"?applicationid=#{APPLICATION_ID}"))
          
            doc.elements.each("*/data/ontologyBean"){ |element|  
              view = parseOntology(element)
            }  
#        rescue Exception =>e
          
#        end
        return view
      end
      
      def self.getViews(ontology_id)
        views = []
#        begin
          
          doc = REXML::Document.new(open(BASE_URL + VIEW_VERSIONS_PATH.gsub("%ONT%",ontology_id)+"?applicationid=#{APPLICATION_ID}"))
            doc.elements.each("*/data/list/list"){ |element|
              virtual_view = []

              element.elements.each{ |version|      
                virtual_view << parseOntology(version)
              }
              views << virtual_view
            }  
#        rescue Exception =>e
          
#        end
  
        return views
      end      
      
      
      
      def self.getCategories()
         categories=nil
         
           doc = REXML::Document.new(open(BASE_URL+CATEGORIES_PATH+"?applicationid=#{APPLICATION_ID}"))

           categories = errorCheck(doc)
           unless categories.nil?
             return categories
           end

           categories = {}
           time = Time.now
            doc.elements.each("*/data/list/categoryBean"){ |element| 
              category = parseCategory(element)
            categories[category[:id].to_s]=category 
           }
     #      puts "getCategories Parse Time: #{Time.now-time}"
          return categories
        
        
      end

    ##
    # Gets a concept node.
    ##
    def self.getNode(ontology,node_id,view = false)
      if view
        concept_uri = BASE_URL+VIEW_CONCEPT_PATH.gsub("%VIEW%",ontology.to_s).gsub("%CONC%",CGI.escape(node_id))+"&applicationid=#{APPLICATION_ID}&maxnumchildren=500"
      else
        concept_uri = BASE_URL+CONCEPT_PATH.gsub("%ONT%",ontology.to_s).gsub("%CONC%",CGI.escape(node_id))+"&applicationid=#{APPLICATION_ID}&maxnumchildren=500"
      end
      
      return getConcept(ontology,concept_uri)
    end

    ##
    # Gets a light version of a concept node. Used for tree browsing.
    ##
    def self.getLightNode(ontology,node_id,view = false)
      if view
        concept_uri = BASE_URL+VIEW_CONCEPT_PATH.gsub("%VIEW%",ontology.to_s).gsub("%CONC%",CGI.escape(node_id))+"&applicationid=#{APPLICATION_ID}&maxnumchildren=500&light=true"
      else
        concept_uri = BASE_URL+CONCEPT_PATH.gsub("%ONT%",ontology.to_s).gsub("%CONC%",CGI.escape(node_id))+"&applicationid=#{APPLICATION_ID}&maxnumchildren=500&light=true"
      end
      
      return getConcept(ontology,concept_uri)
    end
      
      def self.getTopLevelNodes(ontology,view = false)
        node = nil
        RAILS_DEFAULT_LOGGER.debug "Retrieve top level nodes"
        RAILS_DEFAULT_LOGGER.debug BASE_URL+CONCEPT_PATH.gsub("%ONT%",ontology.to_s).gsub("%CONC%","root")+"&applicationid=#{APPLICATION_ID}&maxnumchildren=200"
          if view
            doc = REXML::Document.new(open(BASE_URL+VIEW_CONCEPT_PATH.gsub("%VIEW%",ontology.to_s).gsub("%CONC%","root")+"&applicationid=#{APPLICATION_ID}&maxnumchildren=200"))            
          else
            doc = REXML::Document.new(open(BASE_URL+CONCEPT_PATH.gsub("%ONT%",ontology.to_s).gsub("%CONC%","root")+"&applicationid=#{APPLICATION_ID}&maxnumchildren=200"))
          end
         time = Time.now
         node = errorCheck(doc)         
         unless node.nil?
           return node
         end
                  
          doc.elements.each("*/data/classBean"){ |element|  
          node = parseConcept(element,ontology)
         }

        return node.children
      end

      def self.getOntologyList()
        ontologies=nil
        
         doc = REXML::Document.new(open(BASE_URL+ONTOLOGIES_PATH.gsub("%ONT%","")+"?applicationid=#{APPLICATION_ID}"))
         
         ontologies = errorCheck(doc)
         
         unless ontologies.nil?
           return ontologies
         end

         ontologies = []
         time = Time.now
          doc.elements.each("*/data/list/ontologyBean"){ |element| 
          ontologies << parseOntology(element)
         }
#         puts "getOntologyList Parse Time: #{Time.now-time}"
#         puts ontologies.size
        return ontologies
      end
      
      def self.getOntologyVersions(ontology)

         doc = REXML::Document.new(open(BASE_URL+VERSIONS_PATH.gsub("%ONT%",ontology.to_s)+"?applicationid=#{APPLICATION_ID}"))
        
         ontologies = errorCheck(doc)

         unless ontologies.nil?
           return ontologies
         end

        ontologies=[]

         time = Time.now
          doc.elements.each("*/data/list/ontologyBean"){ |element|  
          ontologies << parseOntology(element)
         }
#         puts "getOntologyVersions Parse Time: #{Time.now-time}"
        return ontologies
      end
      
      
      
      def self.getOntology(ontology)
        ont = nil
       # begin
          RAILS_DEFAULT_LOGGER.debug "Retrieving ontology"
          RAILS_DEFAULT_LOGGER.debug BASE_URL + ONTOLOGIES_PATH.gsub("%ONT%",ontology.to_s)+"?applicationid=#{APPLICATION_ID}"
          doc = REXML::Document.new(open(BASE_URL + ONTOLOGIES_PATH.gsub("%ONT%",ontology.to_s)+"?applicationid=#{APPLICATION_ID}"))
        #rescue Exception=>e
        #  doc =  REXML::Document.new(e.io.read)
        #end
            ont = errorCheck(doc)

             unless ont.nil?
               return ont
             end
          
         time = Time.now
            doc.elements.each("*/data/ontologyBean"){ |element|  
            ont = parseOntology(element)
          }                    
 #        puts "getOntology Parse Time: #{Time.now-time}"
         
      #  if versions
       #   doc = REXML::Document.new(open(BASE_URL+ONTOLOGY_PATH.gsub("%ONT%",ontology)))
      #  end
        return ont
      end
      
      ##
      # Used to retrieve data from back-end REST service, then parse from the resulting metrics bean.
      # Returns an OntologyMetricsWrapper object.
      ## 
      def self.getOntologyMetrics(ontology)
        ont = nil
          
          RAILS_DEFAULT_LOGGER.debug "Retrieving ontology metrics"
          RAILS_DEFAULT_LOGGER.debug BASE_URL + METRICS_PATH.gsub("%ONT%",ontology.to_s)+"?applicationid=#{APPLICATION_ID}"
          begin
            doc = REXML::Document.new(open(BASE_URL + METRICS_PATH.gsub("%ONT%",ontology.to_s)+"?applicationid=#{APPLICATION_ID}"))
          rescue Exception=>e
            RAILS_DEFAULT_LOGGER.debug "getOntologyMetrics error: #{e.message}"
            return ont
          end
          
            ont = errorCheck(doc)

             unless ont.nil?
               return ont
             end
          
         time = Time.now
            doc.elements.each("*/data/ontologyMetricsBean"){ |element|
            ont = parseOntologyMetrics(element)
         }                    

        return ont
      end

      def self.parseOntology(ontology)
          ont = nil
 #         puts "Ontology: #{ontology}"
            doc = REXML::Document.new(open(BASE_URL + PARSE_ONTOLOGY.gsub("%ONT%",ontology.to_s)))
            
                 ont = errorCheck(doc)

                   unless ont.nil?
                     return ont
                   end
            
           time = Time.now
              doc.elements.each("*/data/ontologyBean"){ |element|  
              ont = parseOntology(element)
            }                    
 #          puts "getOntology Parse Time: #{Time.now-time}"

        #  if versions
         #   doc = REXML::Document.new(open(BASE_URL+ONTOLOGY_PATH.gsub("%ONT%",ontology)))
        #  end
          return ont
      
      end
      def self.getLatestOntology(ontology)
         ont = nil

            doc = REXML::Document.new(open(BASE_URL + VIRTUAL_URI_PATH.gsub("%ONT%",ontology.to_s).gsub("%CONC%","")))
            
              ont = errorCheck(doc)

                 unless ont.nil?
                   return ont
                 end
            
           time = Time.now
              doc.elements.each("*/data/ontologyBean"){ |element|  
              ont = parseOntology(element)
            }                    
 #          puts "getOntology Parse Time: #{Time.now-time}"

        #  if versions
         #   doc = REXML::Document.new(open(BASE_URL+ONTOLOGY_PATH.gsub("%ONT%",ontology)))
        #  end
          return ont 
        
      end
      

  ##
  # Get a path from a given concept to the root of the ontology.
  ##
  def self.getPathToRoot(ontology,source,light=nil)
    root = nil
     
    RAILS_DEFAULT_LOGGER.debug "Retrieve path to root"
    RAILS_DEFAULT_LOGGER.debug BASE_URL+PATH_PATH.gsub("%ONT%",ontology.to_s).gsub("%CONC%",CGI.escape(source))+"&light=false&maxnumchildren=100"
    doc = REXML::Document.new(open(BASE_URL+PATH_PATH.gsub("%ONT%",ontology.to_s).gsub("%CONC%",CGI.escape(source))+"&light=false&maxnumchildren=100"))
     
    root = errorCheck(doc)

    unless root.nil?
      return root
    end
     
    time = Time.now
    doc.elements.each("*/data/classBean"){ |element|  
      root = parseConcept(element,ontology)
    }
    RAILS_DEFAULT_LOGGER.debug "getPathToRoot Parse Time: #{Time.now-time}"

    return root
  end
      
       def self.getNodeNameExact(ontologies,search,page)
         
         if ontologies.to_s.eql?("0")
           ontologies=""
         else
           ontologies = "ontologyids=#{ontologies.join(",")}&"
         end
         

         begin
             doc = REXML::Document.new(open(BASE_URL+SEARCH_PATH.gsub("%ONT%",ontologies).gsub("%query%",search.gsub(" ","%20"))+"&isexactmatch=1&pagesize=50&pagenum=#{page}&includeproperties=0"))
            rescue Exception=>e
               doc =  REXML::Document.new(e.io.read)

             end   
                results = errorCheck(doc)

                   unless results.nil?
                     return results
                   end 
           results = []

             time = Time.now
              doc.elements.each("*/data/page/contents"){ |element|  
              results = parseSearchResults(element)
             }
             pages = 1
             
             doc.elements.each("*/data/page"){|element|
               pages = element.elements["numPages"].get_text.value
               }
             

           return results,pages

        
       end   
       def self.getNodeNameContains(ontologies,search,page)
         
         if ontologies.to_s.eql?("0")
           ontologies=""
         else
           ontologies = "ontologyids=#{ontologies.join(",")}&"
         end
         
#        puts BASE_URL+SEARCH_PATH.gsub("%ONT%",ontologies).gsub("%query%",search.gsub(" ","%20"))+"isexactmatch=0&pagesize=50&pagenum=#{page}&includeproperties=0"
        begin
            doc = REXML::Document.new(open(BASE_URL+SEARCH_PATH.gsub("%ONT%",ontologies).gsub("%query%",search.gsub(" ","%20"))+"&isexactmatch=0&pagesize=50&pagenum=#{page}&includeproperties=0&maxnumhits=15"))
           rescue Exception=>e
              doc =  REXML::Document.new(e.io.read)

            end   
               results = errorCheck(doc)

                  unless results.nil?
                    return results
                  end 
          results = []
            
            time = Time.now
             doc.elements.each("*/data/page/contents"){ |element|  
             results = parseSearchResults(element)
            }
              pages = 1

              doc.elements.each("*/data/page"){|element|
                pages = element.elements["numPages"].get_text.value
                }


            return results,pages
 
        end
        
        def self.getUsers()

          doc = REXML::Document.new(open(BASE_URL+USERS_PATH))
          
               results = errorCheck(doc)

                  unless results.nil?
                    return results
                  end
          results = []          
          time = Time.now
           doc.elements.each("*/data/list/userBean"){ |element|  
           results << parseUser(element)
          }
 #       puts "getUsers Parse Time: #{Time.now-time}"
        return results
          
        end
        
        def self.getUser(user_id)
          user=nil
          doc = REXML::Document.new(open(BASE_URL+USER_PATH.gsub("%USR%",user_id.to_s)))
          
                  user = errorCheck(doc)

                      unless user.nil?
                        return user
                      end
          
          time = Time.now
           doc.elements.each("*/data/userBean"){ |element|  
           user = parseUser(element)
          }
 #       puts "getUsers Parse Time: #{Time.now-time}"
        return user
        end

        def self.authenticateUser(username,password)
          user=nil
   #       puts BASE_URL+AUTH_PATH+"?username=#{username}&password=#{password}&applicationid=#{APPLICATION_ID}"
          begin
          doc = REXML::Document.new(open(BASE_URL+AUTH_PATH+"?username=#{username}&password=#{password}&applicationid=#{APPLICATION_ID}"))
          rescue Exception=>e
            doc =  REXML::Document.new(e.io.read)

          end
             user = errorCheck(doc)

                  unless user.nil?
                    return user
                  end
          
          time = Time.now
           doc.elements.each("*/data/userBean"){ |element|  
           user = parseUser(element)
           user.session_id = doc.elements["success"].elements["sessionId"].get_text.value
           
          }
#           puts "authenticateUser Parse Time: #{Time.now-time}"   
          
          
                    
        return user
        end
        
        def self.createUser(params)
          user = nil
            begin
            doc = REXML::Document.new(postToRestlet(BASE_URL+USERS_PATH.gsub("%USR%","")+"?applicationid=#{APPLICATION_ID}",params))
            rescue Exception=>e
              doc =  REXML::Document.new(e.io.read)

            end
               user = errorCheck(doc)

                    unless user.nil?
                      return user
                    end
            
            time = Time.now
             doc.elements.each("*/data/userBean"){ |element|  
             user = parseUser(element)
            }
  #           puts "createUser Parse Time: #{Time.now-time}"   


          return user
        end
        
        
        
        
        def self.updateUser(params,id)
          user = nil
          begin
          doc = REXML::Document.new(putToRestlet(BASE_URL+USER_PATH.gsub("%USR%",id.to_s)+"?applicationid=#{APPLICATION_ID}",params))
          rescue Exception=>e
            doc =  REXML::Document.new(e.io.read)

          end
             user = errorCheck(doc)

                  unless user.nil?
                    return user
                  end
          
            time = Time.now
            doc.elements.each("*/data/userBean"){ |element|  
            user = parseUser(element)
          }
  #        puts "updateUser Parse Time: #{Time.now-time}"   


          return user
        end  
        
        
        def self.createOntology(params)
            ontology = nil
            
          #  puts BASE_URL+ONTOLOGIES_PATH.gsub("%ONT%","")+"?applicationid=#{APPLICATION_ID}"
              begin
                puts params.inspect
                
              response = postMultiPart(BASE_URL+ONTOLOGIES_PATH.gsub("%ONT%","")+"?applicationid=#{APPLICATION_ID}",params)
              
              puts response
              doc = REXML::Document.new(response)

              rescue Exception=>e
                doc =  REXML::Document.new(e.io.read)
              end
                 ontology = errorCheck(doc)

                      unless ontology.nil?
                        return ontology
                      end
              
              time = Time.now
               doc.elements.each("*/data/ontologyBean"){ |element|  
               ontology = parseOntology(element)
              }
 #              puts "createOntology Parse Time: #{Time.now-time}"   
            

            return ontology
          end
        
        def self.updateOntology(params,version_id)
                  ontology = nil
                    begin
                    doc = REXML::Document.new(putToRestlet(BASE_URL+ONTOLOGIES_PATH.gsub("%ONT%",version_id)+"?applicationid=#{APPLICATION_ID}",params))
                    rescue Exception=>e
                       doc =  REXML::Document.new(e.io.read)

                     end
                    
                         ontology = errorCheck(doc)

                              unless ontology.nil?
                                return ontology
                              end

                    time = Time.now
                     doc.elements.each("*/data/ontologyBean"){ |element|  
                     ontology = parseOntology(element)
                    }
 #                    puts "updateOntology Parse Time: #{Time.now-time}"   
                   
                  return ontology          
          
        end
        
        def self.download(id)          
          return BASE_URL+"/ontologies/download/#{id}"
        end
              
   
                
        def self.getAttributeValueContains(ontologies,search,page)
          if ontologies.to_s.eql?("0")
            ontologies=""
          else
            ontologies = "ontologyids=#{ontologies.join(",")}&"
          end
          
          
              begin
                  doc = REXML::Document.new(open(BASE_URL+SEARCH_PATH.gsub("%ONT%",ontologies).gsub("%query%",search.gsub(" ","%20"))+"&isexactmatch=0&pagesize=50&pagenum=#{page}&includeproperties=1"))
                 rescue Exception=>e
                    doc =  REXML::Document.new(e.io.read)

                  end   
                     results = errorCheck(doc)

                        unless results.nil?
                          return results
                        end 
                results = []

                  time = Time.now
                   doc.elements.each("*/data/page/contents"){ |element|  
                   results =parseSearchResults(element)
                  }
                    pages = 1

                    doc.elements.each("*/data/page"){|element|
                      pages = element.elements["numPages"].get_text.value
                      }


                  return results,pages
               
       end
       
        def self.getAttributeValueExact(ontologies,search,page)
          
          if ontologies.to_s.eql?("0")
            ontologies=""
          else
            ontologies = "ontologyids=#{ontologies.join(",")}&"
          end
          
          
              begin
                  doc = REXML::Document.new(open(BASE_URL+SEARCH_PATH.gsub("%ONT%",ontologies).gsub("%query%",search.gsub(" ","%20"))+"&isexactmatch=1&pagesize=50&pagenum=#{page}&includeproperties=1"))
                 rescue Exception=>e
                    doc =  REXML::Document.new(e.io.read)

                  end   
                     results = errorCheck(doc)

                        unless results.nil?
                          return results
                        end 
                results = []

                  time = Time.now
                   doc.elements.each("*/data/page/contents"){ |element|  
                   results = parseSearchResults(element)
                  }
                    pages = 1

                    doc.elements.each("*/data/page"){|element|
                      pages = element.elements["numPages"].get_text.value
                      }


                  return results,pages
         
        end
        
        def self.getDiffs(ontology)
 #           puts BASE_URL+DIFFS_PATH.gsub("%ONT%",ontology)
          begin

            doc = REXML::Document.new(open(BASE_URL+DIFFS_PATH.gsub("%ONT%",ontology)))
          rescue Exception=>e
            doc =  REXML::Document.new(e.io.read)
          end   
          results = errorCheck(doc)

          unless results.nil?
            return results
          end          
          
          pairs = []
          doc.elements.each("*/data/list") {|pair|

            pair.elements.each{|list|
              pair = []
              list.elements.each{|item|
                 pair << item.get_text.value
              }
              pairs << pair
              }            
            }
          return pairs
        end
       
        def self.diffDownload(ver1,ver2)          
          return BASE_URL+"/diffs/download/#{ver1}/#{ver2}"
        end
    
          


private

  def self.getConcept(ontology,concept_uri)
    node = nil
    
    begin
      RAILS_DEFAULT_LOGGER.debug "Concept retreive url"
      RAILS_DEFAULT_LOGGER.debug concept_uri
      startTime = Time.now
      rest = open(concept_uri)
      RAILS_DEFAULT_LOGGER.debug "Concept retreive (#{Time.now - startTime})"
    rescue Exception=>e
      RAILS_DEFAULT_LOGGER.debug e.inspect
    end
     
    startTime = Time.now
    parser = XML::Parser.io(rest)
    doc = parser.parse
    RAILS_DEFAULT_LOGGER.debug "Concept parse (#{Time.now - startTime})"

    node = errorCheckLibXML(doc)
    
    unless node.nil?
      return node
    end
    
    startTime = Time.now
    doc.find("/*/data/classBean").each{ |element|  
      node = parseConceptLibXML(element,ontology)
    }
    RAILS_DEFAULT_LOGGER.debug "Concept storage (#{Time.now - startTime})"
  
    return node
  end

  def self.postMultiPart(url,paramsHash)
    params=[]
      for param in paramsHash.keys
        if param.eql?("filePath")
          params << file_to_multipart('filePath',paramsHash["filePath"].original_filename,paramsHash["filePath"].content_type,paramsHash["filePath"])
        else
           params << text_to_multipart(param,paramsHash[param])
        end
          
      end

    boundary = '349832898984244898448024464570528145'
    query = 
      params.collect {|p| '--' + boundary + "\r\n" + p}.join('') + "--" + boundary + "--\r\n"
    uri = URI.parse(url)
#    puts "==========="
#    puts query
#    puts "=========== "
    response = Net::HTTP.new(uri.host,$REST_PORT).start.
      post2(uri.path,
            query,
            "Content-type" => "multipart/form-data; boundary=" + boundary)

    return response.body
    
  end

  def self.text_to_multipart(key,value)

    if value.class.to_s.downcase.eql?("array")
     return "Content-Disposition: form-data; name=\"#{CGI::escape(key)}\"\r\n" + 
            "\r\n" + 
            "#{value.join(",")}\r\n"
    else
     return "Content-Disposition: form-data; name=\"#{CGI::escape(key)}\"\r\n" + 
            "\r\n" + 
            "#{value}\r\n"
    end
  end

   def self.file_to_multipart(key,filename,mime_type,content)
     return "Content-Disposition: form-data; name=\"#{CGI::escape(key)}\"; filename=\"#{filename}\"\r\n" +
            "Content-Transfer-Encoding: base64\r\n" +
            "Content-Type: text/plain\r\n" + 
            "\r\n" + 
            content.read() + "\r\n"
   end


  def self.postToRestlet(url,paramsHash)

    for param in paramsHash.keys
      if paramsHash[param].class.to_s.downcase.eql?("array")
        paramsHash[param] = paramsHash[param].join(",")
      end
    end
    res = Net::HTTP.post_form(URI.parse(url),paramsHash)
    return res.body
  end

  def self.putToRestlet(url,paramsHash)
    paramsHash["method"]="PUT"
    for param in paramsHash.keys
      if paramsHash[param].class.to_s.downcase.eql?("array")
        paramsHash[param] = paramsHash[param].join(",")
      end
    end
    res = Net::HTTP.post_form(URI.parse(url),paramsHash)
     return res.body
  end

#  def self.parseSearchResults(searchResultBean)
#    resultHash={}
#    
#    resultHash[:version_id]= searchResultBean.elements["ontologyVersionId"].get_text.value
#    resultHash[:names] = []
#    searchResultBean.elements["names"].elements.each {|element|       
#        resultHash[:names]<<parseConcept(element,resultHash[:version_id])
#    }
#    
#    resultHash[:properties] = []
#    searchResultBean.elements["properties"].elements.each {|element|       
#        resultHash[:properties]<<parseConcept(element,resultHash[:version_id])
#    }
#    
#    resultHash[:metadata] = []
#    searchResultBean.elements["metadata"].elements.each {|element|       
#        resultHash[:metadata]<<parseConcept(element,resultHash[:version_id])
#    }
    
#    puts "Results Hash"
#    puts "----------------"
#    puts resultHash.inspect
#    puts "-----------------"
#    return resultHash   
#  end

  def self.parseSearchResults(searchContents)
    
    searchResults =[]
    searchResultList = searchContents.elements["searchResultList"]

     searchResultList.elements.each("searchBean"){|searchBean|
       search_item = {}
       search_item[:ontologyDisplayLabel]=searchBean.elements["ontologyDisplayLabel"].get_text.value.strip
       search_item[:ontologyVersionId]=searchBean.elements["ontologyVersionId"].get_text.value.strip
       search_item[:ontologyId]=searchBean.elements["ontologyId"].get_text.value.strip
       search_item[:ontologyDisplayLabel]=searchBean.elements["ontologyDisplayLabel"].get_text.value.strip
       search_item[:recordType]=searchBean.elements["recordType"].get_text.value.strip
       search_item[:conceptId]=searchBean.elements["conceptId"].get_text.value.strip
       search_item[:conceptIdShort]=searchBean.elements["conceptIdShort"].get_text.value.strip
       search_item[:preferredName]=searchBean.elements["preferredName"].get_text.value.strip
       search_item[:contents]=searchBean.elements["contents"].get_text.value.strip
       searchResults<< search_item
       }

    return searchResults
    
  end



  def self.parseCategory(categorybeanXML)
    category ={}
    category[:name]=categorybeanXML.elements["name"].get_text.value.strip rescue ""
    category[:id]=categorybeanXML.elements["id"].get_text.value.strip rescue ""
    category[:parentId]=categorybeanXML.elements["parentId"].get_text.value.strip rescue ""    
    return category
  end
  
  ##
  # Parse user data from the returned XML.
  ##
  def self.parseUser(userbeanXML)
    user = UserWrapper.new
    
    user.id = userbeanXML.elements["id"].get_text.value.strip
    user.username = userbeanXML.elements["username"].get_text.value.strip
    user.email = userbeanXML.elements["email"].get_text.value.strip
    user.firstname = userbeanXML.elements["firstname"].get_text.value.strip rescue ""
    user.lastname = userbeanXML.elements["lastname"].get_text.value.strip rescue ""
    user.phone = userbeanXML.elements["phone"].get_text.value.strip rescue ""
    
    roles = []  
    begin
    userbeanXML.elements["roles"].elements.each("string"){ |role|
      roles << role.get_text.value.strip
    } 
    rescue Exception=>e
      RAILS_DEFAULT_LOGGER.debug e.inspect
    end
    
    user.roles = roles
    
    return user
  end

  def self.parseOntology(ontologybeanXML)

    ontology = OntologyWrapper.new
    ontology.id = ontologybeanXML.elements["id"].get_text.value.strip
    ontology.displayLabel= ontologybeanXML.elements["displayLabel"].get_text.value.strip rescue "No Label"
    ontology.ontologyId = ontologybeanXML.elements["ontologyId"].get_text.value.strip
    ontology.userId = ontologybeanXML.elements["userId"].get_text.value.strip rescue ""
    ontology.parentId = ontologybeanXML.elements["parentId"].get_text.value.strip rescue ""
    ontology.format = ontologybeanXML.elements["format"].get_text.value.strip rescue  ""
    ontology.versionNumber = ontologybeanXML.elements["versionNumber"].get_text.value.strip rescue ""
    ontology.internalVersion = ontologybeanXML.elements["internalVersionNumber"].get_text.value.strip
    ontology.versionStatus = ontologybeanXML.elements["versionStatus"].get_text.value.strip rescue ""
    ontology.isCurrent = ontologybeanXML.elements["isCurrent"].get_text.value.strip rescue ""
    ontology.isRemote = ontologybeanXML.elements["isRemote"].get_text.value.strip rescue ""
    ontology.isReviewed = ontologybeanXML.elements["isReviewed"].get_text.value.strip rescue ""
    ontology.statusId = ontologybeanXML.elements["statusId"].get_text.value.strip rescue ""
    ontology.dateReleased =  Date.parse(ontologybeanXML.elements["dateReleased"].get_text.value).strftime('%m/%d/%Y') rescue ""
    ontology.contactName = ontologybeanXML.elements["contactName"].get_text.value.strip rescue ""
    ontology.contactEmail = ontologybeanXML.elements["contactEmail"].get_text.value.strip rescue ""
    ontology.urn = ontologybeanXML.elements["urn"].get_text.value.strip rescue ""
    ontology.isFoundry = ontologybeanXML.elements["isFoundry"].get_text.value.strip rescue ""
    ontology.isManual = ontologybeanXML.elements["isManual"].get_text.value.strip rescue ""
    ontology.filePath = ontologybeanXML.elements["filePath"].get_text.value.strip rescue ""
    ontology.homepage = ontologybeanXML.elements["homepage"].get_text.value.strip rescue ""
    ontology.documentation = ontologybeanXML.elements["documentation"].get_text.value.strip rescue ""
    ontology.publication = ontologybeanXML.elements["publication"].get_text.value.strip rescue ""
    ontology.dateCreated = Date.parse(ontologybeanXML.elements["dateCreated"].get_text.value).strftime('%m/%d/%Y') rescue ""
    ontology.preferredNameSlot=ontologybeanXML.elements["preferredNameSlot"].get_text.value.strip rescue ""
    ontology.synonymSlot=ontologybeanXML.elements["synonymSlot"].get_text.value.strip rescue ""
    ontology.description=ontologybeanXML.elements["description"].get_text.value.strip rescue ""
    ontology.abbreviation=ontologybeanXML.elements["abbreviation"].get_text.value.strip rescue ""    
    ontology.categories = []

    ontologybeanXML.elements["categoryIds"].elements.each{|element|
      ontology.categories<< element.get_text.value.strip
    }
    
    
    #view stuff
    
    
    
      ontology.isView = ontologybeanXML.elements["isView"].get_text.value.strip rescue "" 
      ontology.viewOnOntologyVersionId = ontologybeanXML.elements['viewOnOntologyVersionId'].elements['int'].get_text.value rescue "" 
      ontology.viewDefinition = ontologybeanXML.elements["viewDefinition"].get_text.value.strip rescue "" 
      ontology.viewGenerationEngine = ontologybeanXML.elements["viewGenerationEngine"].get_text.value.strip rescue "" 
      ontology.viewDefinitionLanguage = ontologybeanXML.elements["viewDefinitionLanguage"].get_text.value.strip rescue "" 
    
    ontology.view_ids = []
    ontology.virtual_view_ids=[]
    begin
    ontologybeanXML.elements["hasViews"].elements.each{|element|
      ontology.view_ids<< element.get_text.value.strip
    }
    ontologybeanXML.elements['virtualViewIds'].elements.each{|element|
      ontology.virtual_view_ids<< element.get_text.value.strip
    }
    rescue
    end
    
    return ontology
    
  end
  
  ##
  # Parses data from the ontology metrics bean XML, returns an OntologyMetricsWrapper object.
  ##
  def self.parseOntologyMetrics(ontologybeanXML)

    ontologyMetrics = OntologyMetricsWrapper.new
    ontologyMetrics.id = ontologybeanXML.elements["id"].get_text.value.strip rescue ""
    ontologyMetrics.ontologyId = ontologybeanXML.elements["ontologyId"].get_text.value.strip rescue ""
    ontologyMetrics.numberOfAxioms = ontologybeanXML.elements["numberOfAxioms"].get_text.value.strip.to_i rescue ""
    ontologyMetrics.numberOfClasses = ontologybeanXML.elements["numberOfClasses"].get_text.value.strip.to_i rescue ""
    ontologyMetrics.numberOfIndividuals = ontologybeanXML.elements["numberOfIndividuals"].get_text.value.strip.to_i rescue ""
    ontologyMetrics.numberOfProperties = ontologybeanXML.elements["numberOfProperties"].get_text.value.strip.to_i rescue ""
    ontologyMetrics.maximumDepth = ontologybeanXML.elements["maximumDepth"].get_text.value.strip.to_i rescue ""
    ontologyMetrics.maximumNumberOfSiblings = ontologybeanXML.elements["maximumNumberOfSiblings"].get_text.value.strip.to_i rescue ""
    ontologyMetrics.averageNumberOfSiblings = ontologybeanXML.elements["averageNumberOfSiblings"].get_text.value.strip.to_i rescue ""
    
    begin
    ontologybeanXML.elements["classesWithOneSubclass"].elements.each { |element|
      ontologyMetrics.classesWithOneSubclass << element.get_text.value.strip
      unless defined? first
        ontologyMetrics.classesWithOneSubclassAll = element.get_text.value.strip.eql?("alltriggered")
        ontologyMetrics.classesWithOneSubclassLimitPassed = element.get_text.value.strip.include?("limitpassed") ? 
            element.get_text.value.strip.split(":")[1].to_i : false
        first = false
      end
    }

    ontologybeanXML.elements["classesWithMoreThanXSubclasses"].elements.each { |element|
      class_name = element.elements['string[1]'].get_text.value
      class_count = element.elements['string[2]'].get_text.value.to_i
      ontologyMetrics.classesWithMoreThanXSubclasses[class_name] = class_count
      unless defined? first
        ontologyMetrics.classesWithMoreThanXSubclassesAll = element.elements['string[1]'].get_text.value.strip.eql?("alltriggered")
        ontologyMetrics.classesWithMoreThanXSubclassesLimitPassed = element.elements['string[1]'].get_text.value.strip.include?("limitpassed") ? 
            element.elements['string[2]'].get_text.value.strip.to_i : false
        first = false
      end
   }
    
    ontologybeanXML.elements["classesWithNoDocumentation"].elements.each { |element|
      ontologyMetrics.classesWithNoDocumentation << element.get_text.value.strip
      unless defined? first
        ontologyMetrics.classesWithNoDocumentationAll = element.get_text.value.strip.eql?("alltriggered")
        ontologyMetrics.classesWithNoDocumentationLimitPassed = element.get_text.value.strip.include?("limitpassed") ? 
            element.get_text.value.strip.split(":")[1].to_i : false
        first = false
      end
    }
    
    ontologybeanXML.elements["classesWithNoAuthor"].elements.each { |element|
      ontologyMetrics.classesWithNoAuthor << element.get_text.value.strip
      unless defined? first
        ontologyMetrics.classesWithNoAuthorAll = element.get_text.value.strip.eql?("alltriggered")
        ontologyMetrics.classesWithNoAuthorLimitPassed = element.get_text.value.strip.include?("limitpassed") ? 
            element.get_text.value.strip.split(":")[1].to_i : false
        first = false
      end
    }
    
    ontologybeanXML.elements["classesWithMoreThanOnePropertyValue"].elements.each { |element|
      ontologyMetrics.classesWithMoreThanOnePropertyValue << element.get_text.value.strip
      unless defined? first
        ontologyMetrics.classesWithMoreThanOnePropertyValueAll = element.get_text.value.strip.eql?("alltriggered")
        ontologyMetrics.classesWithMoreThanOnePropertyValueLimitPassed = element.get_text.value.strip.include?("limitpassed") ? 
            element.get_text.value.strip.split(":")[1].to_i : false
        first = false
      end
    }

    # Stop exception checking
    rescue Exception=>e
      RAILS_DEFAULT_LOGGER.debug e.inspect
    end
  
    return ontologyMetrics
  end

  def self.errorCheck(doc)
    response=nil
    errorHolder={}
    begin
    doc.elements.each("org.ncbo.stanford.bean.response.ErrorStatusBean"){ |element|  
      
     errorHolder[:error]=true
     errorHolder[:shortMessage]= element.elements["shortMessage"].get_text.value.strip
     errorHolder[:longMessage]=element.elements["longMessage"].get_text.value.strip
     response=errorHolder
    }
    rescue
    end

    return response
  end

  def self.errorCheckLibXML(doc)
    response=nil
    errorHolder={}
    begin
    doc.elements.each("org.ncbo.stanford.bean.response.ErrorStatusBean"){ |element|  
      
     errorHolder[:error]=true
     errorHolder[:shortMessage]= element.elements["shortMessage"].get_text.value.strip
     errorHolder[:longMessage]=element.elements["longMessage"].get_text.value.strip
     response=errorHolder
    }
    rescue
    end
  
    return response
  end
  
  def self.parseConcept(classbeanXML,ontology)


       node = NodeWrapper.new
       node.child_size=0
         node.id = classbeanXML.elements["id"].get_text.value
         node.fullId = classbeanXML.elements["fullId"].get_text.value rescue ""
         
         node.name = classbeanXML.elements["label"].get_text.value rescue node.id
         node.version_id = ontology
         node.children =[]
         node.properties ={}
         classbeanXML.elements["relations"].elements.each("entry"){ |entry|
#           puts "##########Element###########"
#            puts entry.to_s

    startGet = Time.now
             case entry.elements["string"].get_text.value.strip
               when SUBCLASS
                if entry.elements["list"].attributes["reference"]
                   entry.elements["list"].elements.each(entry.elements["list"].attributes["reference"]){|element|
                     element.elements.each{|classbean|

                         #issue with using reference.. for some reason pulls in extra guys sometimes
                         if classbean.name.eql?("classBean")
                           node.children<<parseConcept(classbean,ontology)
                         end
                         }
                     }
                   
                else
                  entry.elements["list"].elements.each {|element|
#                    puts "------------item in list----------"
#                      puts element.to_s
#                      puts "--------------------------------"
                      node.children<<parseConcept(element,ontology)
                  } 
                end                
               when SUPERCLASS
              
               when CHILDCOUNT
                 node.child_size = entry.elements["int"].get_text.value.to_i
               else                
                 begin
                 node.properties[entry.elements["string"].get_text.value] = entry.elements["list"].elements.map{|element| 
                   if(element.name.eql?("classBean"))
                      parseConcept(element,ontology).name                    
                   else 
                    element.get_text.value unless element.get_text.value.empty? 
                    
                   end}.join(" | ") #rescue ""
                  rescue Exception =>e

                    
                  end
               end
        }
        
        node.children.sort!{|x,y| x.name.downcase<=>y.name.downcase}
        
        return node
  end

  def self.parseConceptLibXML(classbeanXML,ontology)
    # check if we're at the root node
    root = classbeanXML.path == "/success/data/classBean" ? true : false

    # Get basic info and initialize the node.
    node = getConceptBasicInfo(classbeanXML,ontology)
     
    if root
      # look for child nodes and process if found
      search = classbeanXML.path + "/relations/entry[string='SubClass']/list/classBean"
      results = classbeanXML.first.find(search)
      unless results.empty?
        results.each do |child|
          node.children << parseConceptLibXML(child,ontology)
        end
      end
    end
          
    if root       
      # find all other properties
      search = classbeanXML.path + "/relations/entry"
      classbeanXML.first.find(search).each do |entry|
        # check to see if the entry is a relationship (signified by [R]), if it is move on
        if classbeanXML.first.find(entry.path + "/string").first.content[0,3].eql?("[R]") ||
                classbeanXML.first.find(entry.path + "/string").first.content[0,10].eql?("SuperClass")
          next
        end
        # check to see if this entry has a list of classBeans
        beans = classbeanXML.first.find(entry.path + "/list/classBean")
        list_content = []
        if !beans.empty?
          beans.each do |bean|
            bean_label = classbeanXML.first.find(bean.path + "/label")
            list_content << bean_label.first.content unless bean_label.first.nil?
          end
        else
          # if there's no classBeans, process the list normally
          list = classbeanXML.first.find(entry.path + "/list/string")
          list.each do |item|
            list_content << item.content
          end
        end
        node.properties[classbeanXML.first.find(entry.path + "/string").first.content] = list_content.join(" | ")
      end # stop processing relation entries
       
    end # stop root node processing
     
    node.children.sort!{|x,y| x.name.downcase<=>y.name.downcase}
    return node
  end
  
  def self.buildPathToRootTree(classbeanXML,ontology)

    node = getConceptBasicInfo(classbeanXML,ontology)
    
    # look for child nodes and process if found
    search = classbeanXML.path + "/relations/entry[string='SubClass']/list/classBean"
    results = classbeanXML.first.find(search)
    unless results.empty?
      results.each do |child|
        # If we're about to process a path we've seen, don't continue.
        if @seen_paths[child.path]
          next
        end
        @seen_paths[child.path] = 1
        node.children << buildPathToRootTree(child,ontology)
        node.children.sort! { |a,b| a.name.downcase <=> b.name.downcase }
      end
    end
    
    return node
  end
  
  def self.getConceptBasicInfo(classbeanXML,ontology)

    # build a node object
    node = NodeWrapper.new
    # set default child size
    node.child_size=0
    # get node.id
    id = classbeanXML.first.find(classbeanXML.path + "/id")
    node.id = id.first.content unless id.first.nil?
    # get fullId
    fullId = classbeanXML.first.find(classbeanXML.path + "/fullId")
    node.fullId = fullId.first.content unless fullId.first.nil?
    # get label
    label = classbeanXML.first.find(classbeanXML.path + "/label")
    node.name = label.first.content unless label.first.nil?
    # get type
    type = classbeanXML.first.find(classbeanXML.path + "/type")
    node.type = type.first.content unless type.first.nil?
    # get childcount info
    childcount = classbeanXML.first.find(classbeanXML.path + "/relations/entry[string='ChildCount']/int")
    node.child_size = childcount.first.content.to_i unless childcount.first.nil?
    # get isBrowsable info
    node.is_browsable = node.type.downcase.eql?("class")
    # get synonyms
    synonyms = classbeanXML.first.find(classbeanXML.path + "/synonyms/string")
    node.synonyms = []
    synonyms.each do |synonym|
      node.synonyms << synonym.content
    end
    # get definitions
    definitions = classbeanXML.first.find(classbeanXML.path + "/definitions/string")
    node.definitions = []
    definitions.each do |definition|
      node.definitions << definition.content
    end
    
     
    node.version_id = ontology
    node.children = []
    node.properties = {}
      
    return node
  end
  
end
