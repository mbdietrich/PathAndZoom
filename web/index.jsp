<%-- 
    Document   : index
    Created on : 15/01/2014, 8:18:35 PM
    Author     : Max
--%>

<%@page contentType="text/html" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
    <head>
        <meta charset="utf-8">
        <title>D3 Test</title>
        <link rel="stylesheet" type="text/css" href="style.css" media="screen" />
        <script src="lib/d3_local.js"></script>
        <script src="lib/topojson_local.js"></script>
        <script src="lib/jquery_local.js"></script>
    </head>
    <body>


        <div class = "control">

            <p>
                <a href="#item1" class = "tab">Navigate Countries</a>
                <a href="#item2" class = "tab">City Data</a>

            <div class="items">
                <div id="item1" class="tab"><table>
                        <tr><td>Select a country:</td></tr>
                        <tr><td><select id="countryList"></td></tr>

                        <td><input type="Submit" value="Go to Country" onclick="goToLoc(document.getElementById('countryList').value);"></input></td>
                        <tr><td><select id="pathList" size="10"></td></tr>
                        <tr>
                            <td><input type="Submit" value="Add to Path" onclick="addToPath(document.getElementById('countryList').value);"></input></td>
                            <td><input type="Submit" value="Remove from Path" onclick="removeFromPath(getSelected(document.getElementById('pathList')));"></input></td>
                        </tr><tr>
                            <td><input type="Submit" value="Follow Path" onclick="FollowPath(0);"></input></td>
                        </tr>
                    </table>
                </div>
                <div id="item2" class="tab">

                    <table class = "infotable">
                        <tr><b><td>City Name</td><td id="citytable_name">...</td></b></tr>
                        <tr><td>Country</td><td id="citytable_country">...</td></tr>
                        <tr><td>Megacity?</td><td id="citytable_mega">...</td></tr>
                    </table>

                    <div class = "commentDivider">
                        <div id="comments" class = "commentbox">

                        </div>
                        <div id="CommentEditor">
                            <textarea maxlength = "200" placeholder = "Write a new comment..." id="cityInput"></textarea>
                            <br><br>

                            <input type="Submit" value="Submit Comment" id="commentSubmit" disabled="true" onclick="
                                    var name = document.getElementById('citytable_name').innerHTML;
                                    var msg = document.getElementById('cityInput').value;
                                    $.post('comment', {city_name: name, comment: msg});
                                    updateComments(name);
                                   ">
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <script>
            var active;
            //Zoom threshold after which to display features
            var CITY_THRESHOLD = 5;
            //How far we should scale into a selection
            var SCALE_FACTOR = 1200;
            //Scale factor of fonts
            var FONT_SCALE = 0.1;
            //How fast we should zoom. Lower numbers zoom faster.
            var ANIMATION_DELAY = 3;
            //How large the ping effect should be, in proportion to the height of the screen.
            var PING_SIZE = 0.2;


            var projection = d3.geo.mercator();
            var path = d3.geo.path()
                    .projection(projection)
                    .pointRadius(0.5);
            var svg = d3.select("body").append("svg")
                    .attr("class", "map")
                    .attr("onresize", 'width = $(".map").width(),height = $(".map").height();');

            var width = $(".map").width(),
                    height = $(".map").height();

            var g = svg.append("g")
            //Flag to keep track of whether cities are currently being displayed.
            var showCities = false;
            //Array of country and city data
            var countries, cities;
            //Prepare City data

            var zoom = d3.behavior.zoom()
                    .scaleExtent([1, 100])        
            .on("zoom", function(){
                    g.attr("transform", "translate(" + d3.event.translate + ")scale(" + d3.event.scale +")");
            });

            d3.json("data/ne_110m_cities.json", function(error, topo) {

                cities = topo.features;
                //Add city elements
                g.append("g").attr("order", 0).selectAll("path")
                        .data(cities)
                        .enter().append("path")
                        .attr("d", path)
                        .attr("class", "city hidden")
                        .attr("id", function(d, i) {
                            return "city" + i;
                        })
                        .on("mouseover", function(d) {
                            var label = g.select('.' + escapeWhitespace(d.properties.NAME));
                            label.style("display", "block");
                        })
                        .on("mouseout", function(d) {
                            var label = g.select('.' + escapeWhitespace(d.properties.NAME));
                            label.style("display", "none");
                        })
                        .on("click", function(d) {
                            document.getElementById("citytable_name").innerHTML = d.properties.NAME;
                            document.getElementById("citytable_country").innerHTML = d.properties.SOV0NAME;
                            document.getElementById("citytable_mega").innerHTML = (d.properties.MEGACITY === 0) ? "No" : "Yes";
                            updateComments(d.properties.NAME);
                        });
                //Labels
                g.selectAll(".city-label")
                        .data(cities)
                        .enter().append("text")
                        .attr("class", function(d) {
                            return "city-label " + escapeWhitespace(d.properties.NAME);
                        })
                        .attr("transform", function(d) {
                            return "translate(" + path.centroid(d) + ")";
                        })
                        .attr("dy", "0.35em")
                        .text(function(d) {
                            return d.properties.NAME;
                        })
            });
            //Prepare country data
            d3.json("data/ne_110m_topo.json", function(error, topo) {

                countries = topo.features;
                //Add country elements
                g.insert("g", "g").attr("order", 1).selectAll("path")
                        .data(countries)
                        .enter().append("path")
                        .attr("d", path)
                        .attr("class", "feature")
                        .attr("id", function(d, i) {
                            return "topo" + i;
                        })
                        .on("click", clickCountry)
                        .on("mouseover", function(d) {
                            if (showCities) {
                                var label = g.select('.' + escapeWhitespace(d.properties.name));
                                label.style("display", "block");
                            }

                        })
                        .on("mouseout", function(d) {
                            var label = g.select('.' + escapeWhitespace(d.properties.name));
                            label.style("display", "none");
                        });
                //Populate country selector
                for (var i = 0; i < countries.length; i++) {
                    var entry = document.createElement("option");
                    entry.text = countries[i].properties.name;
                    entry.value = i;
                    document.getElementById("countryList").appendChild(entry);
                }

                //Labels
                g.selectAll(".country-label")
                        .data(countries)
                        .enter().append("text")
                        .attr("class", function(d) {
                            return "country-label " + escapeWhitespace(d.properties.name);
                        })
                        .attr("transform", function(d) {
                            return "translate(" + path.centroid(d) + ")";
                        })
                        .attr("dx", function(d) {
                            return '-' + (d.properties.name.length / 4) + "em";
                        })
                        .style("font-size", function(d) {
                            var b = path.bounds(d);
                            var width = b[1][0] - b[0][0];
                            return width * FONT_SCALE + "px";
                        })
                        .text(function(d) {
                            return d.properties.name;
                        });
                        
                        svg.call(zoom);
            });
            var start = [width / 2, height / 2, height], end = [width / 2, height / 2, height];
            function clickCountry(d) {
                move(d);
            }

            function move(d, cb) {

                callback = function() {
                    highlight();
                    if (cb) {
                        cb();
                    }
                };
                if (active === d)
                    return reset();
                var b = path.bounds(d);
                var x = (((b[1][0] + b[0][0]) / 2)),
                        y = (((b[1][1] + b[0][1]) / 2)),
                        scale = SCALE_FACTOR / Math.max(width / (b[1][0] - b[0][0]), height / (b[1][1] - b[0][1]));
                end[0] = x;
                end[1] = y;
                end[2] = scale;

                sb = getRealBounds();
                start = [sb[0][0], sb[0][1], height / d3.transform(g.attr("transform")).scale[0]];


//TODO fix starting point
                var center = [width / 2, height / 2],
                        i = d3.interpolateZoom(start, end);
                function highlight() {
                    g.selectAll(".active").classed("active", false);
                    active = d;
                    g.selectAll("#topo" + countries.indexOf(d)).classed("active", true);
                }


                g.transition()
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
                    if (k >= CITY_THRESHOLD && !showCities) {
                        //Display cities
                        showCities = true;
                        g.selectAll(".city").classed("hidden", false);
                    }
                    else if (k < CITY_THRESHOLD && showCities) {
                        //Hide cities
                        showCities = false;
                        g.selectAll(".city").classed("hidden", true);
                    }

                    return "translate(" + (center[0] - p[0] * k) + "," + (center[1] - p[1] * k) + ")scale(" + k + ")";
                }
            }

            function updateComments(cityName) {
                //Load comments

                $.get("comment", {city_name: cityName}, function(resp) {
                    document.getElementById("commentSubmit").disabled = false;
                    commentBox = document.getElementById("comments");
                    commentBox.innerHTML = "";
                    for (var i = 0; i < resp.messages.length; i++) {

                        cLine = document.createElement("div");
                        cLine.setAttribute("class", "comment");
                        cLine.innerHTML = resp.messages[i];
                        commentBox.appendChild(cLine);
                    }
                });
            }

            function reset() {
                g.selectAll(".active").classed("active", active = false);
                g.transition().duration(750).attr("transform", "scale(" + ")");
                start = [width / 2, height / 2, height]
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
                country = countries[index];
                transitionList.push(country);
                var entry = document.createElement("option");
                entry.value = index;
                entry.text = country.properties.name;
                entry.setAttribute("ondblclick", 'goToLoc(' + index + ');');
                entry.setAttribute("onmouseover", 'ping(' + index + ')')
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
                if (transitionList.length > index) {
                    move(transitionList[index], function() {
                        FollowPath(index + 1);
                    });
                }
            }

            function escapeWhitespace(str) {
                function escapeRegExp(x) {
                    return x.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&");
                }
                return str.replace(new RegExp(escapeRegExp(' '), 'g'), '_');
            }


            function getSelected(elem) {
                return elem.options[elem.selectedIndex].value;
            }


            //Pings a country on the scren
            function ping(index) {

                var source = countries[index];

                var center = path.centroid(source);
                var screenvars = getAbsoluteBounds();

                var xdist = Math.abs(center[0] - screenvars[0][0]);
                var ydist = Math.abs(center[1] - screenvars[0][1]);

                var startR = 0;

                //Only adjust radius if the target is off the map
                if ((xdist) > (screenvars[1][0]) || (ydist) > (screenvars[1][1])) {
                    if (xdist === 0) {
                        //Perfectly vertical alignment
                        startR = ydist - (screenvars[1][1]);
                    }
                    else if (ydist === 0) {
                        //Perfectly horizontal alignment
                        startR = xdist - (screenvars[1][0]);
                    }
                    else {

                        var xdy = (xdist / ydist);
                        var screenRatio = width / height;
                        var scaleVar = ((xdy) >= screenRatio) ? (xdist / (Math.abs(xdist - screenvars[1][0]))) : (ydist / (Math.abs(ydist - screenvars[1][1])));
                        var dist = Math.sqrt(xdist * xdist + ydist * ydist);

                        startR = dist / scaleVar;
                    }

                }

                var endR = startR + screenvars[1][1] * PING_SIZE;

                //TODO render circles
                g.append("circle")
                        .attr("class", "ping")
                        .attr("cx", center[0])
                        .attr("cy", center[1])
                        .attr("r", startR)
                        .transition()
                        .duration(750)
                        .style("stroke-opacity", 0.25)
                        .attr("r", endR)
                        .each("end", function() {
                            g.select(".ping").remove();
                        });
            }

            //Convert the screen coords into data coords
            function getRealBounds() {
                var transforms = d3.transform(g.attr("transform"));

                var tx = transforms.translate[0];
                var ty = transforms.translate[1];
                var sc = height / transforms.scale[1];

                var xcenter = ((width / 2) - tx) / transforms.scale[0];
                var ycenter = ((height / 2) - ty) / transforms.scale[0];

                var xspan = width * sc / SCALE_FACTOR;
                var yspan = height * sc / SCALE_FACTOR;

                return [[xcenter, ycenter], [xspan, yspan]];

            }


            //Convert 
            function getAbsoluteBounds() {
                var transforms = d3.transform(g.attr("transform"));

                var tx = transforms.translate[0];
                var ty = transforms.translate[1];

                var xcenter = ((width / 2) - tx) / transforms.scale[0];
                var ycenter = ((height / 2) - ty) / transforms.scale[0];

                return [[xcenter, ycenter], [(width / 2) / transforms.scale[1], (height / 2) / transforms.scale[1]]];
            }

        </script>
    </body>
</html>
