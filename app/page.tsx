'use client';

import React, { useState, useEffect } from 'react';
import './workflow.css';
import { Product, CustomerDebt } from '../types/pos';
import { dataService, INITIAL_PRODUCTS, INITIAL_DEBTS } from '../lib/dataService';
import { MarakiAppSystem } from '../components/MarakiAppSystem';

export default function Page() {
  const [products, setProducts] = useState<Product[]>(INITIAL_PRODUCTS);
  const [debts, setDebts] = useState<CustomerDebt[]>(INITIAL_DEBTS);
  const [isLoading, setIsLoading] = useState<boolean>(true);

  useEffect(() => {
    async function loadData() {
      try {
        const fetchedProducts = await dataService.getProducts();
        setProducts(fetchedProducts);
        const fetchedDebts = await dataService.getCustomerDebts();
        setDebts(fetchedDebts);
      } catch (err) {
        console.error('Error initializing data from service:', err);
      } finally {
        setIsLoading(false);
      }
    }
    loadData();
  }, []);

  return (
    <MarakiAppSystem
      initialProducts={products}
      initialDebts={debts}
    />
  );
}
