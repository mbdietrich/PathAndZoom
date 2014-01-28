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

            var speed = 2;

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


            var start = [width / 2, height / 2, height / 0.85], end = [width / 2, height / 2, height / 0.85];

            function click(d){
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
                        //TODO rework scale.
                        scale = scaleFactor / Math.max(width / (b[1][0] - b[0][0]), height / (b[1][1] - b[0][1]));

                end[0] = x;
                end[1] = y;
                end[2] = scale;

                var center = [width / 2, height / 2],
                        i = d3.interpolateZoom(start, end);

                console.log("Duration: " + i.duration);


                function highlight() {
                    g.selectAll(".active").classed("active", false);
                    g.classed("active", active = d);
                }

                g.attr("transform", transform(start))
                        .transition()
                        .delay(250)
                        .duration(i.duration * speed)
                        .attrTween("transform", function() {
                            return function(t) {
                                return transform(i(t));
                            };
                        })
                                .each("end", callback);
                start = [x, y, scale];



                function transform(p) {
                    //It appears k is the width of the selection we want to end with.
                    var k = height / p[2];
                    return "translate(" + (center[0] - p[0] * k) + "," + (center[1] - p[1] * k) + ")scale(" + k + ")";
                }
            }


            function reset() {
                g.selectAll(".active").classed("active", active = false);
                g.transition().duration(750).attr("transform", "scale(0.85)");
                start = [width / 2, height / 2, height / 0.85]
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
                if(pathList.options.length > 0){
                    pathList.remove(pathList.options.selectedIndex);
                }

            }

            function FollowPath(index) {
                console.log("Now moving to Country #"+countries.indexOf(transitionList[index]));
                if (transitionList.length > index) {
                    move(transitionList[index], function() {
                        FollowPath(index + 1);
                    });
                }
            }


            function getSelected(elem) {
                return elem.options[elem.selectedIndex].value;
            }
        </script>

        <div class = "control">
            <table>
                <tr><td>Select a country ID (0-246):</td></tr>
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
