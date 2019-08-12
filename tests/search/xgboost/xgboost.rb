# Copyright 2019 Oath Inc. Licensed under the terms of the Apache 2.0 license. See LICENSE in the project root.

require 'indexed_search_test'
require 'json'

class XGBoostServing < IndexedSearchTest

  def setup
    @valgrid = false
    set_owner("jobergum")
    set_description("Test XGBoost model representation in Vespa")

    system("pip3 install xgboost sklearn")
    system("mkdir -p #{selfdir}/app/models/")
    preds = `python3 #{selfdir}/train.py #{selfdir}/feature-map.txt  #{selfdir}/app/models/ #{selfdir}`
    @predictions = JSON.parse(preds) 
  end

  def compare(vespa_prediction,dataset)
    xgboost_prediction = @predictions[dataset]
    print("Comparing for #{dataset}")
    for i in (0...xgboost_prediction.length) 
      assert_in_delta(xgboost_prediction[i], vespa_prediction[i],0.0001, message="Vespa prediction for data id #{i} does not match")
    end
  end

  def test_xgboost
    deploy("#{selfdir}/app")
    start

    #Feed files generated from setup/train.py 
    feed(:file => "#{selfdir}/diabetes-feed.json")
    feed(:file => "#{selfdir}/breast_cancer-feed.json")
    wait_for_hitcount("query=sddocname:x", 569 + 442)

    regression_diabetes = getVespaPrediction("diabetes", "regression-diabetes")
    compare(regression_diabetes, "regression_diabetes")

    regression_breast_cancer = getVespaPrediction("breast_cancer", "regression-breast_cancer")
    compare(regression_breast_cancer, "regression_breast_cancer")

    binary_breast_cancer = getVespaPrediction("breast_cancer", "binary-probability-breast_cancer")
    compare(binary_breast_cancer, "binary_breast_cancer")
  end

  def getVespaPrediction(dataset,rankProfile)
    result = search("/search/?query=dataset:#{dataset}&format=json&hits=1000&ranking=#{rankProfile}")
    tree = JSON.parse(result.xmldata)
    hits = tree["root"]["children"]
    predictions = {}
    hits.each do |hit|
      score = hit['relevance']
      id = hit['fields']['id']
      predictions[id] = score
    end
    predictions_array = []
    predictions.keys().sort().each do |id| 
      predictions_array.push(predictions[id])
    end
    return predictions_array
  end

  def teardown
    stop
  end

end
