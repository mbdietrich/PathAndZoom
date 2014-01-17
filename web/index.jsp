<%-- 
    Document   : index
    Created on : 15/01/2014, 8:18:35 PM
    Author     : Max
--%>

<%@page contentType="text/html" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<style>

</style>
<html>
    <head>
        <meta charset="utf-8">
        <title>D3 Test</title>
        <link rel="stylesheet" type="text/css" href="style.css" media="screen" />
        <script src="http://d3js.org/d3.v3.min.js"></script>
        <script src="http://d3js.org/topojson.v1.js"></script>
    </head>
    <body>
        <script>
            var width = 800,
                    height = 640,
                    active;

            var scaleFactor = 1600;

            var projection = d3.geo.mercator();

            var path = d3.geo.path()
                    .projection(projection);

            var svg = d3.select("body").append("svg")
                    //.attr("width", width)
                    //.attr("height", height)
                    .attr("class", "map");

            var g = svg.append("g");
            
            var countries;
            
            d3.json("data/world-50m.json", function(error, topo) {
                
                countries = topojson.feature(topo, topo.objects.countries).features
                
                g.selectAll("path")
                        .data(countries)
                        .enter().append("path")
                        .attr("d", path)
                        .attr("class", "feature")
                        .on("click", click);
            });


            var start = [width / 2, height / 2, height/0.85], end = [width / 2, height / 2, height/0.85];

            function click(d) {

                if (active === d)
                    return reset();

                var b = path.bounds(d);
                var center = projection.translate();
                var x = (((b[1][0] + b[0][0]) / 2)),
                        y = (((b[1][1] + b[0][1]) / 2)),
                        //TODO rework scale.
                        scale = scaleFactor / Math.max( width/(b[1][0] - b[0][0]), height/(b[1][1] - b[0][1]));

                end[0] = x;
                end[1] = y;
                end[2] = scale;

                var center = [width / 2, height / 2],
                        i = d3.interpolateZoom(start, end);

                        console.log("Duration: "+i.duration);

                g.attr("transform", transform(start))
                        .transition()
                        .delay(250)
                        .duration(i.duration * 2)
                        .attrTween("transform", function() {
                            return function(t) {
                                return transform(i(t));
                            };
                        });

                start = [x, y, scale];

                g.selectAll(".active").classed("active", false);
                d3.select(this).classed("active", active = d);

                function transform(p) {
                    //It appears k is the width of the selection we want to end with.
                    var k = height / p[2];
                    return "translate(" + (center[0] - p[0] * k) + "," + (center[1] - p[1] * k) + ")scale(" + k + ")";
                }
            }

            function reset() {
                g.selectAll(".active").classed("active", active = false);
                g.transition().duration(750).attr("transform", "scale(0.85)");
                start = [width / 2, height / 2, height/0.85]
            }
            
            function goToLoc(index){
                click(countries[index]);
            }

        </script>
        
        <div class = "control">
            <table>
                <tr><td>Select a country ID (0-246):</td></tr>
                <tr><td><input type="number" min="0" max="246" value="0" name="ind" id="ind"></input></td><td><input type="Submit" value="Go!" onclick="goToLoc(document.getElementById('ind').value);"></input></td></tr>
            </table>
        </div>
    </body>
</html>
