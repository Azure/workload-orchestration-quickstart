@export()
func HelmChart(repo string, version string) object => {
  components: [
    {
      name: 'helmcomponent'
      type: 'helm.v3'
      properties: {
        chart: {
          repo: repo
          version: version
          wait: true
          timeout: '5m'
        }
      }
    }
  ]
}

@export()
func HelmChartWithStaging(repo string, version string, acrId string, images array) object => {
  components: [
    {
      name: 'helmcomponent'
      type: 'helm.v3'
      properties: union({
        chart: {
          repo: repo
          version: version
          wait: true
          timeout: '5m'
        }
      }, {
        staged: {
          acrResourceId: acrId
          images: images
        }
      })
    }
  ]
}

