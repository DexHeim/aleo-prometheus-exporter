# aleo-prometheus-exporter

Based on amazing idea and research from @pawadski https://github.com/pawadski/monitoring_exporter

This setup assume everything is set on the same machine, Prometheus, Exporter, SnarkOS miner.
node should be running already and RPC replay accordingly, installation script check "all" conditions _( well, not really yet )_.
Exporter is "very alpha" at the moment and purely made for beginning of protocol pentest and general entertainment.

Couple of settings in dashboard require node-exporter ( set port for it in prometheus config, example 9200 )

### Installation:

```bash
sudo curl -s -L https://raw.githubusercontent.com/matsuro-hadouken/aleo-prometheus-exporter/main/install.sh | bash
```

_Default port: 9101 otherwise adjust, check install.sh script for more insformation._

### Test after install:

```bash
curl -s 127.0.0.1:9101
```

Prometheus configuration example: _( keep variables names, or it will take long time to configure dashboard )_

* _prometheus - general prometheus metrics_ 9090
* _aleo-exporter - node-exporter_ 9101

```prometheus
global:
  scrape_interval:     15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
    - targets: ['127.0.0.1:9090']

  - job_name: 'aleo-exporter'
    static_configs:
    - targets: ['127.0.0.1:9101']
```

_Datasource name in Grafana default "Prometheus"_

![1](https://user-images.githubusercontent.com/50751381/134052087-0e6082c5-365f-4c03-8be0-408173aea47a.png)
![2](https://user-images.githubusercontent.com/50751381/134052105-1ec959f5-6b8a-412f-88c7-a90a86833082.png)
![3](https://user-images.githubusercontent.com/50751381/134052125-e2a65232-3de3-4135-9a30-e332d63485a0.png)

## To do:

* write HELP for each metrics
