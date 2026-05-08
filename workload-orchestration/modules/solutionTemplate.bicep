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
