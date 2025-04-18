# Changelog

## [1.0.0](https://github.com/scottmckendry/axis/compare/v0.1.0...v1.0.0) (2025-04-18)


### ⚠ BREAKING CHANGES

* **grafana-dashboards:** Update dashboard Traefik Official Kubernetes Dashboard (8 → 9)
* **grafana-dashboards:** Update dashboard Node Exporter Full (37 → 39)
* **grafana-dashboards:** Update dashboard Kubernetes / Views / Namespaces (32 → 42)

### Features

* **cert-manager:** scrape metrics with prometheus ([53e322e](https://github.com/scottmckendry/axis/commit/53e322e428c71edcd02de2833e801e3417b3ae22))
* **container:** update image ghcr.io/prometheus-community/charts/kube-prometheus-stack ( 70.6.0 → 70.7.0 ) ([ae489b0](https://github.com/scottmckendry/axis/commit/ae489b0d132636bf5ac5719f39fa256f89b15759))
* **homepage:** services & widgets for monitoring stack ([17ccbc7](https://github.com/scottmckendry/axis/commit/17ccbc72475b043f2e48e97c2393dfdb5198b39f))
* **monitoring:** add grafana ([7cdda7d](https://github.com/scottmckendry/axis/commit/7cdda7dd6828a05b8238c0ea9cb2eda29faa6eb7))
* **monitoring:** add kube prometheus stack ([f4db620](https://github.com/scottmckendry/axis/commit/f4db620c03b2620c9d19bde991cb92d9d5f7106f))
* **monitoring:** prepare for standalone grafana ([2adcf1a](https://github.com/scottmckendry/axis/commit/2adcf1a8ebc6dc9e148df25e0ffb73b6877e5288))
* **traefik:** scrape metrics with prometheus ([2d506e2](https://github.com/scottmckendry/axis/commit/2d506e257152300f0091b88e007448381fe35dbf))


### Bug Fixes

* **container:** update image ghcr.io/coder/code-server ( 4.99.2 → 4.99.3 ) ([9c62af1](https://github.com/scottmckendry/axis/commit/9c62af180dcdc02e88370c26a651e6d83a8345f0))
* **helm:** update chart traefik ( 35.0.0 → 35.0.1 ) ([fdec9da](https://github.com/scottmckendry/axis/commit/fdec9dae4f807c956cf4842bca8c60072b7faf3f))


### Miscellaneous Chores

* **grafana-dashboards:** Update dashboard Kubernetes / Views / Namespaces (32 → 42) ([5c7ae3c](https://github.com/scottmckendry/axis/commit/5c7ae3c22382aadb05d5170167afea1f4630aafe))
* **grafana-dashboards:** Update dashboard Node Exporter Full (37 → 39) ([c709411](https://github.com/scottmckendry/axis/commit/c709411bbe89379c9790113bd572327cbca3cbc1))
* **grafana-dashboards:** Update dashboard Traefik Official Kubernetes Dashboard (8 → 9) ([e4a1720](https://github.com/scottmckendry/axis/commit/e4a17207fb35b768bf8c419da8850a6ea52dc20a))

## 0.1.0 (2025-04-16)


### ⚠ BREAKING CHANGES

* **helm:** Update chart traefik ( 34.5.0 → 35.0.0 )

### Features

* add backup restore helper script ([e2c03ba](https://github.com/scottmckendry/axis/commit/e2c03ba5dc3dec6c5d3b869f63ff956d7b7931db))
* add ccinvoice ([de08bb1](https://github.com/scottmckendry/axis/commit/de08bb126fc2afe8aa53f2e1232a2b5e55f1ce33))
* add ccinvoice ingressroute ([eac8dc9](https://github.com/scottmckendry/axis/commit/eac8dc90aa34705763ff89f4b410e2b8dc00d965))
* add cert manager staging issuer and cert ([44c267a](https://github.com/scottmckendry/axis/commit/44c267ae695e038e985533a24039bed562417338))
* add cert-manager ([48d2635](https://github.com/scottmckendry/axis/commit/48d26355a5ac57f786dd7317d2c264d38dfa240e))
* add dashboard ingress and middleware ([479df56](https://github.com/scottmckendry/axis/commit/479df56ccfff776f92b643af08c6813a7dea71e1))
* add home assistant ([a93bfbb](https://github.com/scottmckendry/axis/commit/a93bfbb4c90efd96f891469ae4688a435201c1c8))
* add local path provisioner ([061b6e1](https://github.com/scottmckendry/axis/commit/061b6e1583bc963b849848603c786661b11aa32e))
* add metallb ([a8f1ef6](https://github.com/scottmckendry/axis/commit/a8f1ef6adbb2101629315873feafb14fd73a0316))
* add metrics-server ([947c4ad](https://github.com/scottmckendry/axis/commit/947c4adfebbf4f0d5367c0fdde644af0edf98a90))
* add production certificates ([99bc34b](https://github.com/scottmckendry/axis/commit/99bc34bfef43a1c20d25f8e6ec228e6b9703edb7))
* add renovate config ([aec6269](https://github.com/scottmckendry/axis/commit/aec6269bfbd8e4bb99c05168cb25d9f349a8e7ad))
* add traefik lb service ([5ebd31f](https://github.com/scottmckendry/axis/commit/5ebd31f19c3b2ce2a9fabff391949b8f7576ee65))
* add volsync with b2 backup targets ([8a8a126](https://github.com/scottmckendry/axis/commit/8a8a12624dbe8770a7329e34eb1e108cdf32f83d))
* **backups:** add home-assistant restore config ([866acef](https://github.com/scottmckendry/axis/commit/866acef043b17ade684a6a31cd7dac62963ba72f))
* **ci:** init ci workflow, add releaseplease job ([6b51952](https://github.com/scottmckendry/axis/commit/6b51952f3aa4044552017c35b884b008a0f73f1d))
* **common:** add app-template helm chart ([ba38a28](https://github.com/scottmckendry/axis/commit/ba38a2810324ca0285ec4da87476956dd1140d2f))
* consistent naming convention to simplify backup/restore ([49dc035](https://github.com/scottmckendry/axis/commit/49dc035182d9cf0b36bb5537bae5f00b297745e8))
* **container:** update image ghcr.io/gethomepage/homepage ( v1.0.4 → v1.1.1 ) ([e0369a6](https://github.com/scottmckendry/axis/commit/e0369a67e43efb2adac35e5afae41029ec65e834))
* deploy homepage (config wip) ([b65b496](https://github.com/scottmckendry/axis/commit/b65b4962c91ac2aae75d7b3cc0e0d95366f9e0fb))
* dynamic storage classes for backup restore ([cb055f4](https://github.com/scottmckendry/axis/commit/cb055f4eacf1cfe86943e252958e329949fbedb1))
* **flux:** add Flux sync manifests ([dcf4ce3](https://github.com/scottmckendry/axis/commit/dcf4ce3da6852bd238835e22bc88c9b31966373a))
* **flux:** add Flux v2.5.1 component manifests ([045fe6f](https://github.com/scottmckendry/axis/commit/045fe6f53a8eeaa10f5414321c114a0fb2e61460))
* fluxcd sops configuration ([acbb067](https://github.com/scottmckendry/axis/commit/acbb0677bab75f549f133cb124e7ea2d102a9196))
* gitops style talos config management ([42f065b](https://github.com/scottmckendry/axis/commit/42f065b3edbe68f440330276e3e66a3ea7d759f5))
* **helm:** Update chart traefik ( 34.5.0 → 35.0.0 ) ([94d6784](https://github.com/scottmckendry/axis/commit/94d6784931bfbd64e1e3013bbb73098a84181e4d))
* **home-assistant:** add auth middleware for code server ([9df6ca5](https://github.com/scottmckendry/axis/commit/9df6ca513df6da7bdfbd1f94392b7f9926f67344))
* **home-assistant:** add code server for managing config ([83bcb9b](https://github.com/scottmckendry/axis/commit/83bcb9b457906cc8f446b1ff9a96b5a4adde7a77))
* **home-assistant:** add homepage link and b2 configuration ([076dc2e](https://github.com/scottmckendry/axis/commit/076dc2ee4b5e926d474e34cda135cf0e5ef0b59c))
* **homepage:** add auth ([f02de1a](https://github.com/scottmckendry/axis/commit/f02de1aa9635b87d67f9a8e430c7918313f28a5e))
* **homepage:** add code server link ([49bbc42](https://github.com/scottmckendry/axis/commit/49bbc42c7e96b9ccd462ccef4ce2eab2a4af31ba))
* **homepage:** add home-assistant widget ([389f962](https://github.com/scottmckendry/axis/commit/389f962306ca027068d8a920e334ada81aa6635c))
* **homepage:** add traefik ([00976f4](https://github.com/scottmckendry/axis/commit/00976f4859cfe84fd73d8c84a86428325c716427))
* improve robustness of sops script ([c7c5d68](https://github.com/scottmckendry/axis/commit/c7c5d6806e2965064c1833ee783e2d700785e949))
* initialise traefik proxy ([81bb77c](https://github.com/scottmckendry/axis/commit/81bb77c37678921e8c8fef6df38d3167ea83165b))
* interactive backup restore ([ccb8552](https://github.com/scottmckendry/axis/commit/ccb8552ff56159f4e6529feae708974a29d2094c))
* prepare traefik for cert-manager ([3d80e65](https://github.com/scottmckendry/axis/commit/3d80e65820a21e4cb1e71d1558a5d4e18b7df177))
* secret management with sops/age ([7c1d1e6](https://github.com/scottmckendry/axis/commit/7c1d1e67e8dd94a5205879f6757e38ea22f3e9c3))
* split task files, add volsync tasks ([0108b16](https://github.com/scottmckendry/axis/commit/0108b16803069539aacea4a9cd6703aa4f67c749))
* talos cluster bootstrap ([3d4ef51](https://github.com/scottmckendry/axis/commit/3d4ef514d237ed2fef50a534da6bc497079bb9cc))
* **traefik:** add custom title to tinyauth ([a24ac96](https://github.com/scottmckendry/axis/commit/a24ac96f1f15f8209d9ee22159d3852c031fae0a))
* **traefik:** add tinyauth middleware ([5c9e27e](https://github.com/scottmckendry/axis/commit/5c9e27ebc84ef78a1b2952062667d0a433b25ad9))
* **traefik:** tinyauth high availability! ([3b7229a](https://github.com/scottmckendry/axis/commit/3b7229a82d9a966af84476d88285bc519576d60e))
* ux improvements for interactive backups ([a77ffc3](https://github.com/scottmckendry/axis/commit/a77ffc3e0068fa3fd56b562538fb8f7b956d8c0f))
* wip backup selection script ([05584ae](https://github.com/scottmckendry/axis/commit/05584aed19a5cdab4ebea656a2d37f1c73c61f73))


### Bug Fixes

* add decryption spec to gotk-sync ([94ff766](https://github.com/scottmckendry/axis/commit/94ff766cda5e9df57f5353844335c4dadd90b2af))
* add dedicated namespace for path provisioner with pod security label ([f3e901d](https://github.com/scottmckendry/axis/commit/f3e901d916bd1629dd965f99400ba28b923cf495))
* add missing secret ([8a8a126](https://github.com/scottmckendry/axis/commit/8a8a12624dbe8770a7329e34eb1e108cdf32f83d))
* **helm:** update chart metallb ( 0.14.7 → 0.14.9 ) ([8a7a3b0](https://github.com/scottmckendry/axis/commit/8a7a3b040df5363eed29066826f1f9d9ed8f528b))
* **helm:** update chart metrics-server ( 3.12.0 → 3.12.2 ) ([754cb61](https://github.com/scottmckendry/axis/commit/754cb61be26530fd5b668b0b1fd607ad9607468e))
* **home-assistant:** add namespace annotation for backups ([f1409c9](https://github.com/scottmckendry/axis/commit/f1409c9f5e6b974dbb701c217f13b6739973594d))
* **home-assistant:** backup-appropriate volume mappings ([a11dbeb](https://github.com/scottmckendry/axis/commit/a11dbeba272eae29ac849bae6227fd9e49f50df8))
* **homepage:** pin container version ([46287b8](https://github.com/scottmckendry/axis/commit/46287b8ac21342cf9a3e1409dc1676217393981a))
* patch talos nodes to allow metallb arp requests ([7ac2c85](https://github.com/scottmckendry/axis/commit/7ac2c85cd93dfbf1ac796c14c91c1e8a1d9b8c35))
* **sops:** mac mismatch ([52577a9](https://github.com/scottmckendry/axis/commit/52577a99af8be51e0c0641b467330634189d5ff3))
* **traefik:** prevent tinyauth redirecting to itself ([db120e6](https://github.com/scottmckendry/axis/commit/db120e6e1a82c28fcf00953e0bac4cac917a59af))
