
// load final data initially so page doesn't lag when
// selecting neighborhoods
var TAX_FINAL_DATA = [];
$.getJSON("./data/lots_421a.geojson", function (data) {
    TAX_FINAL_DATA = data
})


mapboxgl.accessToken = 'pk.eyJ1Ijoid3NoZW55YyIsImEiOiJja2w3YjNvd3YxZnc1Mm5wZWp1MnVqZGh2In0.-wG4LWFGN76Nf-AEigxu2A';

//loading map
var map = new mapboxgl.Map({
    container: 'mapContainer', // container ID
    style: 'mapbox://styles/mapbox/light-v9', // style URL
    center: [-73.92013728138733, 40.71401732482218,], // starting position [lng, lat]
    zoom: 11 // starting zoom
});


// add navigation control in top right
var nav = new mapboxgl.NavigationControl();
map.addControl(nav, 'top-left');


//search bar

var geocoder = new MapboxGeocoder({
    accessToken: mapboxgl.accessToken,
    mapboxgl: mapboxgl
});

map.addControl(geocoder);

map.on('load', function () {

    // adding base layer of boros
    map.addSource('boros', {
        type: 'geojson',
        data: './data/boro.geojson'
    });

    // add outlines for boros
    map.addLayer({
        'id': 'boro-outlines',
        'type': 'line',
        'source': 'boros',
        'paint': {
            'line-color': 'gray',
            'line-width': 2
        }
    });

    // adding in layer of just lots 
    map.addSource('taxlots', {
        type: 'geojson',
        data: './data/lots_421a.geojson'
    });

    map.addLayer({
        'id': 'tax-lots',
        'type': 'fill',
        'source': 'taxlots',
        'paint': {
            'fill-color': '#5D3FD3'
        }
    });

    // add outlines for lots
    map.addLayer({
        'id': 'lot-outlines',
        'type': 'line',
        'source': 'taxlots',
        'paint': {
            'line-color': 'black',
            'line-width': 0.5
        }
    });


    // add outlines for selected lots
    map.addSource('highlight-feature', {
        'type': 'geojson',
        'data': {
            'type': 'FeatureCollection',
            'features': []
        }
    });

    map.addLayer({
        'id': 'highlight-fill',
        'type': 'fill',
        'source': 'highlight-feature',
        'paint': {
            'fill-color': '#eacf47 '
        }
    });

    map.addLayer({
        'id': 'highlight-outline',
        'type': 'line',
        'source': 'highlight-feature',
        'paint': {
            'line-width': 3,
            'line-opacity': 1,
            'line-color': '#e83553'
        },
        'layout': {
            'line-join': 'bevel'
        }
    });

});

//Target the span element used in the sidebar
var addDisplay = document.getElementById('infoContainer');

map.on('click', 'tax-lots', function (e) {

    const msg = document.getElementById('welcome-msg');
    if (msg) {
        msg.remove();
    }

    // Set variables equal to the current feature's:
    // address, BBL, # of res units,
    //tax benefit description, benefit start year, exemption end year
    //

    if (e.features.length > 0) {
        var LotElements = e.features.map((feature, idx) => {
            var {
                properties
            } = feature;

            return `<div>
        <div>
          <strong>Address: </strong>&nbsp;
          <span id = "lot_add">${properties.Address}</span>
        </div>
        <div>
          <strong>BBL:</strong>&nbsp;
          <span id="lot_bbl">${properties.BBL}</span>
        </div>
        <div>
          <strong>Number of Residential Units:</strong>&nbsp;
          <span id="units_res">${properties.UnitsRs}</span>
        </div>
        <div>
          <strong>Benefit Type:</strong>&nbsp;
          <span id="benefit_type">${properties.dscrptn}</span>
          <ul style='font-size:16px;'>
          <li><b>Benefit Start Year:</b>${properties.bnftstr}</li>
          <li><b>Benefit End Year:</b> ${properties.exmp_nd}</li>
          <li><b>Years Receiving Benefit:</b> ${properties.crrnt__}</li>
          <li><b>For this type of 421-a, benefits start phasing out by year:</b> ${properties.phs_t_s === 'null' ? 'N/A' : properties.phs_t_s}</li>
          <li><b>Is this building’s 421-a phasing out?:</b> ${properties.flg_phs === 'null' ? 'N/A' : properties.flg_phs}</li>
          <li><b>Is this building receiving a version of 421-a(16)?*:</b> ${properties.f_42116}</li></ul>
        <div>
        <i>*If the building receives 421-a(16) benefits, it cannot collect rent surcharges.</i>
        </div>

        <br/>

        <div>
         <strong>Building Construction Details: </strong>&nbsp;
          <ul>
          <li><b>Construction Start Date:</b>${properties.apprvd_ === 'null' ? 'N/A' : properties.apprvd_}</li>
          <li><b>Year Completed:</b> ${properties.yer_cmp === 'null' ? 'N/A' : properties.yer_cmp}</li>
          <li><b>35 Years From Completed Construction:</b> ${properties.yr_c_35 === 'null' ? 'N/A' : properties.yr_c_35}</li>
          </ul>

          <div><b>When will my apartment's rent stabilization status end?</b>
          <ul>
          <li><b>For income-restricted units*:</b> ${properties.rs_inc === 'null' ? 'N/A' : properties.rs_inc}</li>
          <li><b>For market-rate units:</b> ${properties.rs_mr === 'null' ? 'N/A' : properties.rs_mr}</li>
          </ul>
          <i>*Income-restricted units are rented via HPD's Housing Connect.</i>
          </div>

        </div>
        </div>

    
        </div>       
      </div>`
        });

        var RSElements = e.features.map((feature, idx) => {
            var {
                properties
            } = feature;

            return `<div>

            <div>
        <strong>Is my landlord allowed to charge a 2.2% surcharge during the phase-out of the 421-a benefits?</strong>
        </div>

         <div>
         <span>A building receiving 421-a benefits may be allowed to add an annual 2.2% surcharge 
        to the rent for <i>some</i> units during each year of the phase-out period of the building’s 
        421-a benefits. <u>If this building is able to collect surcharges from your unit</u>, those surcharges would be limited to: 
        <b>${properties.surchrg === 'null' ? 'N/A' : properties.surchrg}</b>
        </span>

       <div>
       <br/>

        <span> The 2.2% surcharge is <b>not</b> collectible from the following categories of 
        units in such buildings:</span>
      <ul>
      <li>421-a affordable units that were built without governmental assistance 
        pursuant to Section 6-08 of HPD Rules, </li>
      <li>421-a affordable units that were built with governmental assistance pursuant to 
        Section 6-08 of HPD Rules and that are subject to a regulatory agreement prohibiting the 
        collection of such surcharges, and  </li>
      <li>GEA SGA units and GEA 60% AMI units pursuant to Section 6-09 of HPD Rules 
        (these are two different types of 421-a income-restricted units in buildings that 
        commenced construction on or after July 1, 2008 and on or before December 31, 2015, 
        as defined in 28 RCNY 6-09).</li>
      <li>All rental units in buildings that receive 421-a(16) benefits.</li>
      </ul>
      </div>
        
        </div>`
        });



        map.setLayoutProperty('highlight-outline', 'visibility', 'visible');
        map.setLayoutProperty('highlight-fill', 'visibility', 'visible');
        map.getSource('highlight-feature').setData(e.features[0].geometry);
        infoContainer.innerHTML = LotElements.join('');
        rsInfo.innerHTML = RSElements.join('');

        //zooming map to building that's been clicked
        var coords = flatten(e.features[0].geometry.coordinates)
        var turfFeatures = turf.points(coords);
        var newCenter = turf.center(turfFeatures);
        var currentZoom = map.getZoom();
        if (currentZoom >= 16) {
        } else {
            map.flyTo({
                center: newCenter.geometry.coordinates,
                zoom: 16,
                speed: 1
            })
        }
    }
});

// recursive array flattener, return array of arrays, in geojson format,
// i.e. [[lng, lat], [lng, lat]]
function flatten(array) {
    if (array[0] instanceof Array) {
        if (!(array[0][0] instanceof Array)) {
            return array
        }
    }
    var newArray = []
    array.forEach(el => newArray = [...newArray, ...el])
    return flatten(newArray)
}



