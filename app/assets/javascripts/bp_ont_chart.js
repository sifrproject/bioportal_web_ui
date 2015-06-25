// Note duplicated code in _visits.html.haml due to Ajax loading
jQuery(document).data().bp.ontChart = {};

jQuery(document).data().bp.ontChart.init = function() {
  Chart.defaults.global.scaleLabel = jQuery(document).data().bp.ont_chart.scaleLabel;
  var data = {
    labels: jQuery(document).data().bp.ont_chart.visitsLabels,
    datasets: [
      {
        label: "Visits",
        fillColor: "rgba(151,187,205,0.2)",
        strokeColor: "rgba(151,187,205,1)",
        pointColor: "rgba(151,187,205,1)",
        pointStrokeColor: "#fff",
        pointHighlightFill: "#fff",
        pointHighlightStroke: "rgba(151,187,205,1)",
        data: jQuery(document).data().bp.ont_chart.visitsData
      }
    ]
  };

  var width = (jQuery("#visits_content").width() || 600).toString();
  var visits_chart = document.getElementById("visits_chart");
  var ctx = visits_chart.getContext("2d");
  visits_chart.width = visits_chart.style.width = width;
  visits_chart.height = visits_chart.style.height = "323";

  var myLineChart = new Chart(ctx).Line(data, { responsive: true });

  // Something funky with Chart.js makes this not always work the first time.
  // The width ends up set to 0 when using responsive mode. So, we try again until it works.
  setTimeout(function() {
    while (visits_chart.width == 0) {
      visits_chart.width = visits_chart.style.width = width;
      visits_chart.height = visits_chart.style.height = "323";
      var myLineChart = new Chart(ctx).Line(data, { responsive: true });
    }
  }, 100);
}