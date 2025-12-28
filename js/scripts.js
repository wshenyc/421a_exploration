
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
    style: 'mapbox://styles/mapbox/light-v11', // style URL
    center: [-73.97604717577194, 40.750535691164316], // starting position [lng, lat]
    zoom: 12 // starting zoom
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
            'fill-color': '#1D4ED8',
            'fill-opacity': 0.8
        }
    });

    // add outlines for lots
    map.addLayer({
        'id': 'lot-outlines',
        'type': 'line',
        'source': 'taxlots',
        'paint': {
            'line-color': '#64748B',
            'line-width': 1
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
            'fill-color': '#FDE68A'
        }
    });

    map.addLayer({
        'id': 'highlight-outline',
        'type': 'line',
        'source': 'highlight-feature',
        'paint': {
            'line-width': 2,
            'line-opacity': 1,
            'line-color': '#B45309'
        },
        'layout': {
            'line-join': 'bevel'
        }
    });

});

//tab boxes
document.querySelectorAll(".tab").forEach(tab => {
    tab.addEventListener("click", () => {
        const target = tab.dataset.tab;

        document.querySelectorAll(".tab").forEach(t =>
            t.classList.remove("active")
        );
        document.querySelectorAll(".panel").forEach(p =>
            p.classList.remove("active")
        );

        tab.classList.add("active");
        document.getElementById(target).classList.add("active");

        map.resize();
    });
});

//Target the span element used in the sidebar

map.on('click', 'tax-lots', function (e) {

    const msg = document.getElementById('welcome-msg');
    if (msg) {
        msg.remove();
    }

    // Set variables equal to the current feature's:
    // address, BBL, # of res units,
    //tax benefit description, benefit start year, exemption end year
    //

    const infoContainer = document.getElementById('infoContainer');
    const surchargeInfo = document.getElementById('surchargeInfo');
    const rsInfo = document.getElementById('rsInfo');


    if (e.features.length > 0) {
        var LotElements = e.features.map((feature, idx) => {
            var {
                properties
            } = feature;

            return `<div>
        <div>
          <strong>Address: </strong>&nbsp;
          <span>${properties.Address}</span>
        </div>
        <div>
          <strong>BBL:</strong>&nbsp;
          <span">${properties.BBL}</span>
        </div>
        <div>
          <strong>Number of Residential Units:</strong>&nbsp;
          <span>${properties.UnitsRs}</span>
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

        </div>

        <div>
         <strong>Other Relevant Info: </strong>&nbsp;
          <ul>
          <li><b>In a Geographic Exclusion Area (GEA)?:</b><i> Working on it!</i></li>
          <li><b>Receiving government assistance?:</b><i> Working on it!</i></li>
          </ul>

        </div>

        </div>

    
        </div>       
      </div>`
        });

        var SurchargeElements = e.features.map((feature, idx) => {
            var {
                properties
            } = feature;

            return `<div>
            <div>
          <strong>Address: </strong>&nbsp;
          <span>${properties.Address}</span>
        </div>
        <hr>

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

        var RSElements = e.features.map((feature, idx) => {
            var {
                properties
            } = feature;

            return `<div>

               <div>
          <strong>Address: </strong>&nbsp;
          <span class = "lot_add">${properties.Address}</span>
        </div>
        <hr>


             <div><b>When will my apartment's rent stabilization status end?</b>
          <ul>
          <li><b>For income-restricted units*:</b> ${properties.rs_inc === 'null' ? 'N/A' : properties.rs_inc}</li>
          <li><b>For market-rate units:</b> ${properties.rs_mr === 'null' ? 'N/A' : properties.rs_mr}</li>
          </ul>
          <i>*Income-restricted units are rented via HPD's Housing Connect.</i>
          </div>

             </div>`
        });



        map.setLayoutProperty('highlight-outline', 'visibility', 'visible');
        map.setLayoutProperty('highlight-fill', 'visibility', 'visible');
        map.getSource('highlight-feature').setData(e.features[0].geometry);
        infoContainer.innerHTML = LotElements.join('');
        surchargeInfo.innerHTML = SurchargeElements.join('');
        rsInfo.innerHTML = RSElements.join('');

        //zooming map to building that's been clicked
        var coords = flatten(e.features[0].geometry.coordinates)
        var turfFeatures = turf.points(coords);
        var newCenter = turf.center(turfFeatures);

        map.flyTo({
            center: newCenter.geometry.coordinates,
            zoom: 16,
            speed: 1
        })

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



