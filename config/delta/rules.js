export default [
  {
    match: {
      // listen to all changes
    },
    callback: {
      url: 'http://mu-search/update',
      method: 'POST'
    },
    options: {
      resourceFormat: "v0.0.1",
      gracePeriod: 2000 // 2 seconds
    }
  },
  {
    match: {
      predicate: {
        type: 'uri',
        value: 'http://mu.semte.ch/vocabularies/ext/taskType'
      }
    },
    callback: {
      url: 'http://sync/delta',
      method: 'POST'
    },
    options: {
      resourceFormat: "v0.0.1",
      gracePeriod: 1000, // 1 seconds
      ignoreFromSelf: true
    }
  }
]
