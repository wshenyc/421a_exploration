
// load final data initially so page doesn't lag when
// selecting neighborhoods
var TAX_FINAL_DATA = [];
$.getJSON("./data/lots_421a.geojson", function(data) {
  TAX_FINAL_DATA = data
})


mapboxgl.accessToken = 'pk.eyJ1Ijoid3NoZW55YyIsImEiOiJja2w3YjNvd3YxZnc1Mm5wZWp1MnVqZGh2In0.-wG4LWFGN76Nf-AEigxu2A';

//loading map
var map = new mapboxgl.Map({
  container: 'mapContainer', // container ID
  style: 'mapbox://styles/mapbox/light-v9', // style URL
  center: [-73.92013728138733, 40.71401732482218,], // starting position [lng, lat]
  zoom: 10.5 // starting zoom
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

map.on('load', function() {

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
var addDisplay = document.getElementById('address');

map.on('click', 'tax-lots', function(e) {
  // Set variables equal to the current feature's:
  // address, BBL, # of res units,
  //tax benefit description, benefit start year, exemption end year
  //

  var address = e.features[0].properties.Address;

  if (e.features.length > 0) {
    var LotElements = e.features.map((feature, idx) => {
      var {
        properties
      } = feature;

      return `<div>
        <div>
         <h3 class="LotItemHeader" style="${idx === 0 ? 'padding-top:0' : ''}">
          ${properties.Address}
          </h3>
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
          <li><b>For this type of 421-a, benefits start phasing out by year:</b> ${properties.phs_t_s}</li>
          <li><b>Is this building’s 421-a phasing out?:</b> ${properties.flg_phs}</li>
          <li><b>Is this building receiving a version of 421-a(16)?*:</b> ${properties.f_42116}</li></ul>
        <div style='font-size:14px; font-weight:bold;'>
        <i>*If the building receives 421-a(16) benefits, it cannot collect rent surcharges.</i>
        </div>
        </div>
        <div>
          <strong>Closing Date:</strong>&nbsp;
          <span id="closingdate">${properties.closing_date}</span>
        </div>
      </div>`
    });
    addDisplay.textContent = address;
    map.setLayoutProperty('highlight-outline', 'visibility', 'visible');
    map.setLayoutProperty('highlight-fill', 'visibility', 'visible');
    map.getSource('highlight-feature').setData(e.features[0].geometry);
    infoContainer.innerHTML = LotElements.join('');

    //zooming map to building that's been clicked
    var coords = flatten(e.features[0].geometry.coordinates)
    var turfFeatures = turf.points(coords);
    var newCenter = turf.center(turfFeatures);
    var currentZoom = map.getZoom();
    if (currentZoom >= 14) {
    } else {
    map.flyTo({
      center: newCenter.geometry.coordinates,
      zoom: 14,
      speed: 1
    })
  }
  }
});






