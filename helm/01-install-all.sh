#!/usr/bin/env bash

set -e

cd ui-chart/
helm upgrade --install ui . -f values-ui.yaml
cd ..

cd catalog-chart/
helm upgrade --install catalog . -f values-catalog.yaml
cd ..

cd cart-chart
helm upgrade --install cart . -f values-cart.yaml
cd ..

cd orders-chart/
helm upgrade --install orders . -f values-orders.yaml
cd ..


cd checkout-chart/
helm upgrade --install checkout . -f values-checkout.yaml
cd ..
