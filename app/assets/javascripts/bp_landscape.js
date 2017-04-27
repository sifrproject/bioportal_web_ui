
/**
 * To show/hide the simple metadata div
 */
function toggleDiv(divId)
{
  var e = document.getElementById(divId + "Div");
  if (e.style.display == 'block') {
    e.style.display = 'none';
    document.getElementById(divId + "Btn").classList.remove("active");
  } else {
    e.style.display = 'block';
    document.getElementById(divId + "Btn").classList.add("active");
  }
}

var chartTooltipLocked = false;

// Creating a pie chart using d3pie.js
// function to generate a pie chart given 4 simple params: the div class name (the html div where the pie chart will go)
// the JSON containing the chart data. groupSmall is a boolean to define if we want to group small values
var createPie = function(divName, json, groupSmall) {
    new d3pie(divName, {
        "footer": {
            "color": "#999999",
            "fontSize": 10,
            "font": "open sans",
            "location": "bottom-left"
        },
        "size": {
            "canvasWidth": document.getElementById(divName).offsetWidth,
            //"canvasHeight": 300,
            "pieOuterRadius": "50%"
        },
        "data": {
            "sortOrder": "value-desc",
            "smallSegmentGrouping": {
              "enabled": groupSmall,
              "value": 5
            },
            "content": json
        },
        callbacks: {
          onMouseoverSegment: function (d) {
            if (chartTooltipLocked == false) {
              d3.select("#chartTooltip")
                .style("left", d3.event.pageX + "px")
                .style("top", d3.event.pageY + "px")
                .style("opacity", 1)
                .style("z-index", 1)
              d3.select("#chartTooltipValue")
                .text(d.data.uri);
              $("#chartTooltip").show();
            }
          },
          onClickSegment: function(d) {
            //dbIds: d.expanded? [] : d.data.dbIds
            var wasLocked = chartTooltipLocked
            if (d.expanded) {
              dbIds = []
              chartTooltipLocked = false;
            } else {
              dbIds = d.data.dbIds
              chartTooltipLocked = true;
            }

            if (wasLocked == true) {
              d3.select("#chartTooltip")
                .style("left", d3.event.pageX + "px")
                .style("top", d3.event.pageY + "px")
                .style("opacity", 1)
              d3.select("#chartTooltipValue")
                .text(d.data.uri);
              $("#chartTooltip").show();
            }
          },
          onMouseoutSegment: function(info) {
            //$("#chartTooltip").hide(); this avoid us to mouseover tooltip text
          }
        },
        "labels": {
            "truncation": {
              "enabled": true,
              "truncateLength": 40
            },
            "outer": {
                "pieDistance": 15
            },
            "inner": {
                "hideWhenLessThanPercentage": 5
            },
            "mainLabel": {
                "fontSize": 11
            },
            "percentage": {
                "color": "#ffffff",
                "decimalPlaces": 0
            },
            "value": {
                "color": "#adadad",
                "fontSize": 11
            },
            "lines": {
                "enabled": true
            }
        },
        "effects": {
            "pullOutSegmentOnClick": {
                "effect": "linear",
                "speed": 400,
                "size": 8
            }
        },
        "misc": {
            "gradient": {
                "enabled": true,
                "percentage": 100
            }
        }
    })
}

// To create a new pie chart: add "%div#prefLabelPieChartDiv" to html and use the createPie function
var naturalLanguagePie = createPie("naturalLanguagePieChartDiv", landscapeData["natural_language_json_pie"], true);

var licensePie = createPie("licensePieChartDiv", landscapeData["licenseProperty_json_pie"], true);

var formalityPie = createPie("formalityPieChartDiv", landscapeData["formalityProperty_json_pie"], true);

var prefLabelPie = createPie("prefLabelPropertyPieChartDiv", landscapeData["prefLabelProperty_json_pie"], false);

var synonymPie = createPie("synonymPropertyPieChartDiv", landscapeData["synonymProperty_json_pie"], false);

var definitionPie = createPie("definitionPropertyPieChartDiv", landscapeData["definitionProperty_json_pie"], false);

var authorPie = createPie("authorPropertyPieChartDiv", landscapeData["authorProperty_json_pie"], false);

// Generate the people tag cloud (from all contributors attributes)
$(function() {
  // When DOM is ready, select the container element and call the jQCloud method, passing the array of words as the first argument.
  $("#peopleCloudChart").jQCloud(landscapeData["people_count_json_cloud"]);
});

// Generate the organization tag cloud (from fundedBy, endorsedBy...), don't show if less than 5 words
$(function() {
  // When DOM is ready, select the container element and call the jQCloud method, passing the array of words as the first argument.
    $("#orgCloudChart").jQCloud(landscapeData["org_count_json_cloud"]);
});

$(function() {
  // When DOM is ready, select the container element and call the jQCloud method, passing the array of words as the first argument.
  $("#notesPeopleCloudChart").jQCloud(landscapeData["notes_people_json_cloud"]);
});

$(function() {
  // When DOM is ready, select the container element and call the jQCloud method, passing the array of words as the first argument.
  $("#notesOntologiesCloudChart").jQCloud(landscapeData["notes_ontologies_json_cloud"]);
});


// Horizontal bar charts for format (OWL, SKOS, UMLS)
var ontologyFormatsContext = document.getElementById("formatCanvas").getContext("2d");
var ontologyFormatsChart = new Chart(ontologyFormatsContext, {
  type: 'horizontalBar',
  data: landscapeData["ontologyFormatsChartJson"],
  options: {
    scales: {
      yAxes: [{
        stacked: true
      }]
    }
  }
});

var groupCountContext = document.getElementById("groupsCanvas").getContext("2d");
var groupCountChart = new Chart(groupCountContext, {
  type: 'bar',
  data: landscapeData["groupCountChartJson"],
  options: {
    scales: {
      yAxes: [{
        stacked: true
      }]
    }
  }
});

var domainCountContext = document.getElementById("domainCanvas").getContext("2d");
var domainCountChart = new Chart(domainCountContext, {
  type: 'bar',
  data: landscapeData["domainCountChartJson"],
  options: {
    scales: {
      yAxes: [{
        stacked: true
      }]
    }
  }
});

var sizeSlicesContext = document.getElementById("sizeSlicesCanvas").getContext("2d");
var sizeSlicesChart = new Chart(sizeSlicesContext, {
  type: 'bar',
  data: landscapeData["sizeSlicesChartJson"],
  options: {
    scales: {
      yAxes: [{
        stacked: true
      }]
    }
  }
});

buildNetwork(landscapeData["ontology_relations_array"]);

function buildNetwork(ontologyRelationsArray) {
  var nodes = new vis.DataSet([]);
  // create an array with edges
  var edges = new vis.DataSet();
  var propertyCount = 1; // To define nodes IDs

  // Hash with nodes id for each ontology URI
  var nodeIds = {};

  if (jQuery("#selected_relations").val() !== null) {
    selected_relations = jQuery("#selected_relations").val()
  }

  // Iterate through all the ontology relations and add them to the network
  for (var i = 0; i < ontologyRelationsArray.length; i++) {
    // If relations have been selected for filtering then we don't show others relations
    if (jQuery("#selected_relations").val() !== null) {
      if (!selected_relations.includes(ontologyRelationsArray[i]["relation"])) {
        continue;
      }
    }
    // Don't create a new node if node exist already, just add a new edge
    if (nodeIds[ontologyRelationsArray[i]["source"]] != null) {
      var sourceNodeNumber = nodeIds[ontologyRelationsArray[i]["source"]];
    } else {
      var sourceNodeNumber = propertyCount;
      nodes.add([
        {id: sourceNodeNumber, label: ontologyRelationsArray[i]["source"]}
      ]);
      nodeIds[ontologyRelationsArray[i]["source"]] = propertyCount;
      propertyCount++;
    }

    if (nodeIds[ontologyRelationsArray[i]["target"]] != null) {
      var targetNodeNumber = nodeIds[ontologyRelationsArray[i]["target"]];
    } else {
      var targetNodeNumber = propertyCount;
      nodes.add([
        {id: targetNodeNumber, label: ontologyRelationsArray[i]["target"]}
      ]);
      nodeIds[ontologyRelationsArray[i]["target"]] = propertyCount;
      propertyCount++;
    }

    // Create edge with prefixed predicate when possible
    edges.add([
      {from: sourceNodeNumber, to: targetNodeNumber, label: ontologyRelationsArray[i]["relation"], font: {align: 'horizontal'}}
    ]);
  }


  // create a network
  var container = document.getElementById("ontologyNetwork");
  // provide the data in the vis format
  var data = {
    nodes: nodes,
    edges: edges
  };
  // Get height of div
  var networkHeight = document.getElementById("networkContainer").clientHeight.toString();

  var options = {
    autoResize: true,
    height: networkHeight,
    groups:{
      useDefaultGroups: true,
      myGroupId:{
        /*node options*/
      }
    },
    edges:{
      color:{inherit:'both'},
      smooth: {
        enabled: true,
        type: "dynamic",
        roundness: 0.5
      }
    },
    nodes: {
      shape: "box"
    },
    physics: {
      enabled: true,
      stabilization: {
        onlyDynamicEdges: false,
        fit: true
      },
      barnesHut: {
        gravitationalConstant: -1500,
        centralGravity: 0.1,
        springLength: 300,
        springConstant: 0.01,
        damping: 0.2,
        avoidOverlap: 0.2
      },
      hierarchicalRepulsion: { // not used atm
        centralGravity: 0.0,
        springLength: 500,
        springConstant: 0.2,
        damping: 1,
        nodeDistance: 170
      },
      solver: 'barnesHut'
    }
    /*configure: {
      enabled: true,
      showButton: true
    }
    interaction:{
      zoomView:false,
      dragView: false
    }*/
  };

  // initialize your network!
  var network = new vis.Network(container, data, options);
  network.fit();
}

// Hide tooltip when click outside of pie chart div
$(document).mouseup(function (e)
{
  var container = $("#pieChartDiv");
  if (!container.is(e.target) // if the target of the click isn't the container...
    && container.has(e.target).length === 0) // ... nor a descendant of the container
  {
    chartTooltipLocked = false;
    $("#chartTooltip").hide();
  }
});

jQuery(document).ready(function() {
  "use strict";
  // enable selected search
  jQuery("#selected_relations").chosen({
    search_contains: true
  });
})

// Hide more properties pie div on load to let the pie lib the time to get the parent div size (to size the pie chart)
window.onload = function() {
  $("#propertiesDiv").hide();
};