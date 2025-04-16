<template>
  <div class="app">
    <header>
      <h1>싱크홀 자동 감지 시스템</h1>
    </header>
    <main>
      <div id="map" ref="mapElement"></div>
      <div v-if="selectedSinkhole" class="info-window">
        <h3>{{ selectedSinkhole.title }}</h3>
        <p>{{ selectedSinkhole.location }}</p>
        <p>{{ formatDate(selectedSinkhole.pubDate) }}</p>
        <a :href="selectedSinkhole.link" target="_blank">기사 보기</a>
      </div>
    </main>
  </div>
</template>

<script>
import { ref, onMounted } from 'vue'
import { Loader } from '@googlemaps/js-api-loader'
import axios from 'axios'

export default {
  name: 'App',
  setup() {
    const mapElement = ref(null)
    const selectedSinkhole = ref(null)
    let map = null
    let markers = []

    const loadMap = async () => {
      const loader = new Loader({
        apiKey: import.meta.env.VITE_GOOGLE_MAPS_API_KEY,
        version: 'weekly'
      })

      const google = await loader.load()
      map = new google.maps.Map(mapElement.value, {
        center: { lat: 36.5, lng: 127.5 },
        zoom: 7
      })
    }

    const loadSinkholes = async () => {
      try {
        const response = await axios.get(import.meta.env.VITE_API_ENDPOINT, {
          headers: {
            'x-api-key': import.meta.env.VITE_API_KEY
          }
        })
        const sinkholes = response.data

        // Clear existing markers
        markers.forEach(marker => marker.setMap(null))
        markers = []

        // Add new markers
        sinkholes.forEach(sinkhole => {
          if (sinkhole.lat && sinkhole.lng) {
            const marker = new google.maps.Marker({
              position: { lat: sinkhole.lat, lng: sinkhole.lng },
              map: map,
              title: sinkhole.title
            })

            marker.addListener('click', () => {
              selectedSinkhole.value = sinkhole
            })

            markers.push(marker)
          }
        })
      } catch (error) {
        console.error('Error loading sinkholes:', error)
      }
    }

    const formatDate = (dateStr) => {
      return new Date(dateStr).toLocaleDateString('ko-KR', {
        year: 'numeric',
        month: 'long',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
      })
    }

    onMounted(async () => {
      await loadMap()
      await loadSinkholes()
      // Refresh data every 5 minutes
      setInterval(loadSinkholes, 300000)
    })

    return {
      mapElement,
      selectedSinkhole,
      formatDate
    }
  }
}
</script>

<style>
.app {
  height: 100vh;
  display: flex;
  flex-direction: column;
}

header {
  padding: 1rem;
  background: #f8f9fa;
  border-bottom: 1px solid #dee2e6;
}

header h1 {
  margin: 0;
  font-size: 1.5rem;
  color: #343a40;
}

main {
  flex: 1;
  display: flex;
  position: relative;
}

#map {
  flex: 1;
  height: 100%;
}

.info-window {
  position: absolute;
  top: 1rem;
  right: 1rem;
  background: white;
  padding: 1rem;
  border-radius: 8px;
  box-shadow: 0 2px 6px rgba(0, 0, 0, 0.1);
  max-width: 300px;
}

.info-window h3 {
  margin: 0 0 0.5rem 0;
  font-size: 1.1rem;
}

.info-window p {
  margin: 0.5rem 0;
  color: #495057;
}

.info-window a {
  display: inline-block;
  margin-top: 0.5rem;
  color: #228be6;
  text-decoration: none;
}

.info-window a:hover {
  text-decoration: underline;
}
</style>
