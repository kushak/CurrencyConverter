//  ViewController.swift
//  Currency conwerter
//
//  Created by user on 20.02.17.
//  Copyright © 2017 Oleg Shipulin. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {

    @IBOutlet weak var label: UILabel!
    
    @IBOutlet weak var pickerFrom: UIPickerView!
    @IBOutlet weak var pickerTo: UIPickerView!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
//    var currencies = ["RUB", "USD", "EUR"]
    var currencies = ["RON", "EUR", "MYR"]
    var rates = [0.0, 0.0, 0.0]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.label.text = "Тут будет курс"
        self.label.layoutIfNeeded()
        self.label.layer.masksToBounds = true
        self.label.layer.cornerRadius = self.label.frame.size.height / 3
        
        self.pickerFrom.dataSource = self
        self.pickerTo.dataSource = self
        
        self.pickerFrom.delegate = self
        self.pickerTo.delegate = self
        
        self.activityIndicator.hidesWhenStopped = true
        
        self.requestCurrentCurrencyRate()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //MARK: - UIPickerViewDataSource
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView == self.pickerTo {
            return self.currenciesExceptBase().count
        }
        
        return self.currencies.count
    }
    
    //MARK: - UIPickerViewDelegat
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView == self.pickerTo {
            return "\(self.rates[row]) \(self.currenciesExceptBase()[row])"
        }
        
        return self.currencies[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        if pickerView == pickerFrom {
            self.pickerTo.reloadAllComponents()
        }
        
        self.requestCurrentCurrencyRate()
    }
    
    func requestCurrentCurrencyRate() {
        self.activityIndicator.startAnimating()
        self.label.text = ""
        
        let baseCurrencyIndex = self.pickerFrom.selectedRow(inComponent: 0)
        let toCurrencyIndex = self.pickerTo.selectedRow(inComponent: 0)
        
        let baseCurrency = self.currencies[baseCurrencyIndex]
        let toCurrency = self.currenciesExceptBase()[toCurrencyIndex]
        
        self.retrieveCurrencyRate(baseCurrency: baseCurrency, toCurrency: toCurrency) {[weak self] (value) in
            DispatchQueue.main.async(execute: {
                if let strongSelf = self {
                    if strongSelf.label.text != value {
                        strongSelf.label.text = value
                    }
                    strongSelf.activityIndicator.stopAnimating()
                    strongSelf.pickerFrom.reloadAllComponents()
                    strongSelf.pickerTo.reloadAllComponents()
                }
            })
        }
    }
    // retrieve - извлечь
    func retrieveCurrencyRate(baseCurrency: String, toCurrency: String, complition: @escaping (String) -> Void) {
        self.requestCurrencyRates(baseCurrency: baseCurrency) {[weak self] (data, error) in
            var string = "No currency retieved!"
            
            if let currentError = error {
                string = currentError.localizedDescription
            } else {
                if let strongSelf = self {
                    string = strongSelf.parseCurrencyRatesResponse(data: data, toCurrency: toCurrency)
                }
            }
            
            complition(string)
        }
    }
    
    func requestCurrencyRates(baseCurrency: String, parseHandler: @escaping (Data?, Error?) -> Void) {
        let url = URL(string: "https://api.fixer.io/latest?base=" + baseCurrency)!
        
        let dataTask = URLSession.shared.dataTask(with: url) {
            (dataReceived, response, error) in
            parseHandler(dataReceived, error)
        }
        
        dataTask.resume()
    }
    
    func parseCurrencyRatesResponse(data: Data?, toCurrency: String) -> String {
        var value: String = ""
        
        do {
            let json = try JSONSerialization.jsonObject(with: data!, options: []) as? Dictionary<String, Any>
            if let parsedJSON = json {
//                print("\(parsedJSON)")
                if let rates = parsedJSON["rates"] as? Dictionary<String, Double>,
                    let baseCurrency = parsedJSON["base"] as? String {
                    
                    if self.rates.count != 0 {
                        self.rates = Array(rates.values)
                    }
                    
                    if self.currencies == ["RON", "EUR", "MYR"] {
                        self.currencies = [baseCurrency]
                        self.currencies += Array(rates.keys) //Добавлеяем все валюты в массив валют
                    }
                    if let rate = rates[toCurrency] {
                        value = "1 \(baseCurrency) = \(rate) \(toCurrency)"
                    } else {
                        value = "No rate for currence \"\(toCurrency)\" found"
                    }
                } else {
                    value = "No \"rates\" field found"
                }
            } else {
                value = "No JSON value parsed"
            }
        } catch {
            value = error.localizedDescription
        }
        
        return value
    }
    
    func currenciesExceptBase() -> [String] {
        var currenciesExceptBase = self.currencies
        currenciesExceptBase.remove(at: self.pickerFrom.selectedRow(inComponent: 0))
        
        return currenciesExceptBase
    }
}

