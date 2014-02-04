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
            
            //Zoom threshold after which to display features
            var CITY_THRESHOLD = 5;

            //How far we should scale into a selection
            var SCALE_FACTOR = 1600;

            //How fast we should zoom. Lower numbers zoom faster.
            var ANIMATION_DELAY = 3;

            var projection = d3.geo.mercator();

            var path = d3.geo.path()
                    .projection(projection)
                    .pointRadius(0.5);

            var svg = d3.select("body").append("svg")
                    .attr("class", "map");

            var g = svg.append("g");

            var showCities = false;

            var countries, cities;

            console.log(path);

            
            d3.json("data/ne_110m_cities.json", function(error, topo) {

                //countries = topojson.feature(topo, topo.features.geometry).features;
                cities = topo.features;
                g.append("g").attr("order", 0).selectAll("path")
                        .data(cities)
                        .enter().append("path")
                        .attr("d", path)
                        .attr("class", "city hidden")
                        .attr("id", function(d, i) {
                            return "city" + i;
                        });
            });
            
            d3.json("data/ne_110m_topo.json", function(error, topo) {

                //countries = topojson.feature(topo, topo.features.geometry).features;
                countries = topo.features;
                g.insert("g", "g").attr("order", 1).selectAll("path")
                        .data(countries)
                        .enter().append("path")
                        .attr("d", path)
                        .attr("class", "feature")
                        .attr("id", function(d, i) {
                            return "topo" + i;
                        })
                        .on("click", click);
            });
            

            var start = [width / 2, height / 2, height / 0.85], end = [width / 2, height / 2, height / 0.85];

            function click(d) {
                move(d);
            }

            function move(d, callback) {

                callback = typeof callback !== 'undefined' ? callback : highlight;

                if (active === d)
                    return reset();

                var b = path.bounds(d);
                var center = projection.translate();
                var x = (((b[1][0] + b[0][0]) / 2)),
                        y = (((b[1][1] + b[0][1]) / 2)),
                        scale = SCALE_FACTOR / Math.max(width / (b[1][0] - b[0][0]), height / (b[1][1] - b[0][1]));

                end[0] = x;
                end[1] = y;
                end[2] = scale;

                var center = [width / 2, height / 2],
                        i = d3.interpolateZoom(start, end);

                console.log("Duration: " + i.duration);


                function highlight() {
                    g.selectAll(".active").classed("active", false);
                    active = d;
                    g.selectAll("#topo" + countries.indexOf(d)).classed("active", true);
                    console.log(countries.indexOf(d));
                }

                g.attr("transform", transform(start))
                        .transition()
                        .delay(250)
                        .duration(i.duration * ANIMATION_DELAY)
                        .attrTween("transform", function() {
                            return function(t) {
                                return transform(i(t));
                            };
                        })
                        .each("end", callback);
                start = [x, y, scale];



                function transform(p) {
                    //k is the width of the selection we want to end with.
                    var k = height / p[2];
                    
                    if(k>=CITY_THRESHOLD && !showCities){
                        //Display cities
                        showCities = true;
                        g.selectAll(".city").classed("hidden", false);
                        
                    }
                    else if(k<CITY_THRESHOLD && showCities){
                        //Hide cities
                        showCities = false;
                        g.selectAll(".city").classed("hidden", true);
                    }
                    
                    return "translate(" + (center[0] - p[0] * k) + "," + (center[1] - p[1] * k) + ")scale(" + k + ")";
                }
            }



            function reset() {
                g.selectAll(".active").classed("active", active = false);
                g.transition().duration(750).attr("transform", "scale(0.85)");
                start = [width / 2, height / 2, height / 0.85]
                showCities = false;
                g.selectAll(".city").classed("hidden", true);
            }

            function goToLoc(index) {
                move(countries[index]);
            }

            var transitionList = [];

            function clearPath() {
                transitionList.length = 0;
            }

            function addToPath(index) {
                transitionList.push(countries[index]);

                var entry = document.createElement("option");
                entry.text = index;
                document.getElementById('pathList').add(entry, null);
            }

            function removeFromPath(index) {
                var loc = transitionList.indexOf(countries[index]);
                if (loc > -1) {
                    transitionList.splice(loc, 1);
                }
                var pathList = document.getElementById('pathList');
                if (pathList.options.length > 0) {
                    pathList.remove(pathList.options.selectedIndex);
                }

            }

            function FollowPath(index) {
                console.log("Now moving to Country #" + countries.indexOf(transitionList[index]));
                if (transitionList.length > index) {
                    move(transitionList[index], function() {
                        FollowPath(index + 1);
                    });
                }
            }


            function getSelected(elem) {
                return elem.options[elem.selectedIndex].value;
            }
            
            window.onload = function(){
                g.selectAll("g").sort(function(a, b){a.order-b.order});
            }
        </script>

        <div class = "control">
            <table>
                <tr><td>Select a country ID (0-175):</td></tr>
                <tr><td><input type="number" min="0" max="246" value="0" name="ind" id="ind"></input></td></tr>
                <tr><td><select id="pathList" size="10"></td></tr>
                <tr>
                    <td><input type="Submit" value="Add to Path" onclick="addToPath(document.getElementById('ind').value);"></input></td>
                    <td><input type="Submit" value="Remove selected from Path" onclick="removeFromPath(getSelected(document.getElementById('pathList')));"></input></td>
                </tr><tr>
                    <td><input type="Submit" value="Go to Location" onclick="goToLoc(document.getElementById('ind').value);"></input></td>
                    <td><input type="Submit" value="Follow Path" onclick="FollowPath(0);"></input></td>
                </tr>
            </table>
        </div>
    </body>
</html>
