'use client';

import React, { useState, useEffect } from 'react';
import {
  Settings, Plus, Database, ShieldAlert, ArrowLeft, Trash2,
  CheckCircle2, DollarSign, PieChart, ShoppingBag, Receipt, AlertCircle, Copy, Check,
  Utensils, Truck, ClipboardList, Calendar, ChevronDown, ChevronUp, FileSpreadsheet,
  Wallet, Smartphone, CreditCard, Coffee, Sparkles, RefreshCw, Sun, Moon
} from 'lucide-react';
import { Product, Order, CustomerDebt, ShiftReconciliation, ManualShiftReconciliation } from '../types/pos';
import { isSupabaseConfigured } from '../lib/supabase';
import { dataService } from '../lib/dataService';

interface AdminDashboardProps {
  products: Product[];
  orders: Order[];
  debts: CustomerDebt[];
  onSaveProduct: (product: Product) => void;
  onToggleAvailability: (productId: string) => void;
  onBack: () => void;
  onOpenManualRecon?: () => void;
}

export function AdminDashboard({
  products,
  orders,
  debts,
  onSaveProduct,
  onToggleAvailability,
  onBack,
  onOpenManualRecon,
}: AdminDashboardProps) {
  const [activeTab, setActiveTab] = useState<'menu' | 'analytics' | 'debts' | 'kitchen' | 'reconciliations' | 'supabase'>('menu');
  const [copied, setCopied] = useState<boolean>(false);
  const [reconciliations, setReconciliations] = useState<ManualShiftReconciliation[]>([]);
  const [expandedReconId, setExpandedReconId] = useState<string | null>(null);
  const [reconFilter, setReconFilter] = useState<'all' | 'day' | 'night'>('all');
  const [isLoadingRecons, setIsLoadingRecons] = useState<boolean>(false);

  useEffect(() => {
    async function loadRecons() {
      setIsLoadingRecons(true);
      try {
        const list = await dataService.getManualReconciliations();
        setReconciliations(list);
      } catch (err) {
        console.error('Error loading reconciliations in AdminDashboard:', err);
      } finally {
        setIsLoadingRecons(false);
      }
    }
    loadRecons();
  }, [activeTab]);

  // Add Product Form state
  const [name, setName] = useState<string>('');
  const [description, setDescription] = useState<string>('');
  const [price, setPrice] = useState<string>('');
  const [category, setCategory] = useState<'Food' | 'Juice'>('Juice');
  const [emoji, setEmoji] = useState<string>('🍹');
  const [tone, setTone] = useState<string>('mango');
  const [imageUrl, setImageUrl] = useState<string>('');
  const [showAddForm, setShowAddForm] = useState<boolean>(false);

  const handleAddProductSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!name || !price) return;
    const newProduct: Product = {
      id: `prod-${Date.now()}`,
      name,
      description: description || name,
      price: Number(price),
      category,
      emoji,
      tone,
      image: imageUrl || undefined,
      isAvailable: true
    };
    onSaveProduct(newProduct);
    setName('');
    setDescription('');
    setPrice('');
    setImageUrl('');
    setShowAddForm(false);
  };

  const handleDeleteProduct = async (id: string) => {
    if (confirm('Are you sure you want to delete this menu item?')) {
      await dataService.deleteProduct(id);
      window.location.reload();
    }
  };

  // Analytics Metrics (ETB)
  const totalRevenue = orders.reduce((sum, o) => sum + o.total, 0);
  const totalOrders = orders.length;
  const cashTotal = orders.filter(o => o.paymentMethod === 'Cash').reduce((sum, o) => sum + o.total, 0);
  const transferTotal = orders.filter(o => o.paymentMethod === 'Transfer').reduce((sum, o) => sum + o.total, 0);
  const creditTotal = orders.filter(o => o.paymentMethod === 'Credit' || o.paymentMethod === 'Pay later').reduce((sum, o) => sum + o.total, 0);
  const deliveryTotal = orders.filter(o => o.paymentMethod === 'Delivery').reduce((sum, o) => sum + o.total, 0);

  const sqlCode = `-- MARAKI JUICE POS & SHIFT RECONCILIATION - SUPABASE SQL SCHEMA
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS public.products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT,
    price NUMERIC(10, 2) NOT NULL,
    category TEXT NOT NULL CHECK (category IN ('Food', 'Juice', 'Beverage')),
    tone TEXT NOT NULL DEFAULT 'mango',
    emoji TEXT NOT NULL DEFAULT '🍹',
    image TEXT,
    is_available BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.shifts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    shift_type TEXT NOT NULL CHECK (shift_type IN ('day', 'night')),
    cashier_name TEXT NOT NULL,
    opening_cups INT NOT NULL DEFAULT 0,
    status TEXT NOT NULL CHECK (status IN ('active', 'closed')) DEFAULT 'active',
    started_at TIMESTAMPTZ DEFAULT NOW(),
    closed_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS public.orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    shift_id UUID REFERENCES public.shifts(id) ON DELETE SET NULL,
    cashier_name TEXT NOT NULL,
    items JSONB NOT NULL,
    subtotal NUMERIC(10, 2) NOT NULL,
    tax NUMERIC(10, 2) NOT NULL,
    total NUMERIC(10, 2) NOT NULL,
    payment_method TEXT NOT NULL CHECK (payment_method IN ('Cash', 'Transfer', 'Pay later', 'Credit', 'Delivery')),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.shift_expenses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    shift_id UUID REFERENCES public.shifts(id) ON DELETE CASCADE,
    category TEXT NOT NULL,
    description TEXT NOT NULL,
    amount NUMERIC(10, 2) NOT NULL,
    logged_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.customer_debts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_name TEXT NOT NULL,
    note TEXT,
    amount NUMERIC(10, 2) NOT NULL,
    is_recovered BOOLEAN NOT NULL DEFAULT false,
    shift_id_created UUID REFERENCES public.shifts(id) ON DELETE SET NULL,
    shift_id_recovered UUID REFERENCES public.shifts(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    recovered_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS public.shift_reconciliations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    shift_id UUID UNIQUE REFERENCES public.shifts(id) ON DELETE CASCADE,
    shift_type TEXT NOT NULL,
    cashier_name TEXT NOT NULL,
    gross_revenue NUMERIC(10, 2) NOT NULL,
    cash_sales NUMERIC(10, 2) NOT NULL,
    transfer_sales NUMERIC(10, 2) NOT NULL,
    credit_sales NUMERIC(10, 2) NOT NULL,
    delivery_sales NUMERIC(10, 2) NOT NULL,
    tip_sales NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    total_orders_count INT NOT NULL,
    opening_cups INT NOT NULL,
    added_cups INT NOT NULL,
    leftover_cups INT NOT NULL,
    calculated_cups_sold INT NOT NULL,
    tablet_cups_sold INT NOT NULL,
    cups_variance INT NOT NULL,
    total_expenses NUMERIC(10, 2) NOT NULL,
    total_recovered_debts NUMERIC(10, 2) NOT NULL,
    net_cash_to_owner NUMERIC(10, 2) NOT NULL,
    shift_notes TEXT,
    closed_at TIMESTAMPTZ DEFAULT NOW()
);`;

  const copySql = () => {
    navigator.clipboard.writeText(sqlCode);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <main className="min-h-screen bg-gray-50 text-gray-900 font-sans">
      {/* Admin Header */}
      <header className="bg-white border-b border-gray-200 px-6 py-4 flex justify-between items-center shadow-sm">
        <div className="flex items-center gap-4">
          <button onClick={onBack} className="p-2 border border-gray-200 rounded-lg hover:bg-gray-50 flex items-center gap-2 text-xs font-semibold text-gray-600">
            <ArrowLeft className="w-4 h-4" /> Exit Admin
          </button>
          <div className="flex items-center gap-3">
            <img src="/logo.jpg" alt="Maraki Logo" className="w-10 h-10 rounded-full object-cover border border-amber-400 shadow-sm" />
            <div>
              <h1 className="text-lg font-bold text-gray-900 leading-tight">Maraki Admin Dashboard</h1>
              <p className="text-[10px] text-gray-500 font-medium">BOLE BRANCH • BACKOFFICE CONTROL</p>
            </div>
          </div>
        </div>

        {/* Tab Switcher */}
        <div className="flex bg-gray-100 p-1 rounded-xl gap-1 text-xs font-bold overflow-x-auto">
          <button
            onClick={() => setActiveTab('menu')}
            className={`px-3.5 py-2 rounded-lg transition-all whitespace-nowrap ${activeTab === 'menu' ? 'bg-white text-gray-900 shadow-sm' : 'text-gray-500 hover:text-gray-900'}`}
          >
            Menu & Products
          </button>
          <button
            onClick={() => setActiveTab('analytics')}
            className={`px-3.5 py-2 rounded-lg transition-all whitespace-nowrap ${activeTab === 'analytics' ? 'bg-white text-gray-900 shadow-sm' : 'text-gray-500 hover:text-gray-900'}`}
          >
            Sales Analytics
          </button>
          <button
            onClick={() => setActiveTab('reconciliations')}
            className={`px-3.5 py-2 rounded-lg transition-all whitespace-nowrap flex items-center gap-1.5 ${activeTab === 'reconciliations' ? 'bg-purple-700 text-white shadow-sm' : 'text-purple-700 hover:bg-purple-50'}`}
          >
            <FileSpreadsheet className="w-3.5 h-3.5" /> የሺፍት ሪፖርቶች ({reconciliations.length})
          </button>
          <button
            onClick={() => setActiveTab('debts')}
            className={`px-3.5 py-2 rounded-lg transition-all whitespace-nowrap ${activeTab === 'debts' ? 'bg-white text-gray-900 shadow-sm' : 'text-gray-500 hover:text-gray-900'}`}
          >
            Customer Debts
          </button>
          <button
            onClick={() => setActiveTab('kitchen')}
            className={`px-3.5 py-2 rounded-lg transition-all whitespace-nowrap ${activeTab === 'kitchen' ? 'bg-white text-gray-900 shadow-sm' : 'text-gray-500 hover:text-gray-900'}`}
          >
            የኩሽና ምርት
          </button>
          <button
            onClick={() => setActiveTab('supabase')}
            className={`px-3.5 py-2 rounded-lg transition-all whitespace-nowrap ${activeTab === 'supabase' ? 'bg-emerald-600 text-white shadow-sm' : 'text-gray-500 hover:text-gray-900'}`}
          >
            Supabase BaaS
          </button>
        </div>
      </header>

      {/* Main Body */}
      <div className="max-w-7xl mx-auto px-6 py-8">
        {/* TAB 1: Menu & Products */}
        {activeTab === 'menu' && (
          <div>
            <div className="flex justify-between items-center mb-6">
              <div>
                <h2 className="text-xl font-bold text-gray-900">Menu Catalog Management</h2>
                <p className="text-xs text-gray-500">Control juice and food prices in ETB, categories, photos, and stock availability.</p>
              </div>
              <button
                onClick={() => setShowAddForm(!showAddForm)}
                className="px-4 py-2.5 bg-primary text-white font-bold text-xs rounded-xl shadow-md hover:bg-primary/90 flex items-center gap-2"
              >
                <Plus className="w-4 h-4" /> Add New Menu Item
              </button>
            </div>

            {/* Add Product Modal Form */}
            {showAddForm && (
              <form onSubmit={handleAddProductSubmit} className="bg-white p-6 rounded-2xl border border-gray-200 shadow-lg mb-8 grid grid-cols-1 md:grid-cols-3 gap-4">
                <div>
                  <label className="text-xs font-bold text-gray-700 block mb-1">Item Name</label>
                  <input
                    required
                    placeholder="e.g. Passion Special Juice"
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                    className="w-full border border-gray-300 rounded-lg p-2 text-xs outline-primary"
                  />
                </div>
                <div>
                  <label className="text-xs font-bold text-gray-700 block mb-1">Description</label>
                  <input
                    placeholder="e.g. Blended with fresh passion fruit"
                    value={description}
                    onChange={(e) => setDescription(e.target.value)}
                    className="w-full border border-gray-300 rounded-lg p-2 text-xs outline-primary"
                  />
                </div>
                <div>
                  <label className="text-xs font-bold text-gray-700 block mb-1">Price (ETB)</label>
                  <input
                    required
                    type="number"
                    placeholder="180"
                    value={price}
                    onFocus={(e) => e.target.select()}
                    onChange={(e) => setPrice(e.target.value.replace(/^0+(?=\d)/, ''))}
                    className="w-full border border-gray-300 rounded-lg p-2 text-xs outline-primary font-bold"
                  />
                </div>
                <div>
                  <label className="text-xs font-bold text-gray-700 block mb-1">Category</label>
                  <select
                    value={category}
                    onChange={(e) => setCategory(e.target.value as 'Food' | 'Juice')}
                    className="w-full border border-gray-300 rounded-lg p-2 text-xs bg-white"
                  >
                    <option value="Juice">Juice</option>
                    <option value="Food">Food</option>
                  </select>
                </div>
                <div>
                  <label className="text-xs font-bold text-gray-700 block mb-1">Image URL (Optional)</label>
                  <input
                    placeholder="/products/maraki_special.png or http..."
                    value={imageUrl}
                    onChange={(e) => setImageUrl(e.target.value)}
                    className="w-full border border-gray-300 rounded-lg p-2 text-xs outline-primary"
                  />
                </div>
                <div>
                  <label className="text-xs font-bold text-gray-700 block mb-1">Emoji Icon</label>
                  <input
                    value={emoji}
                    onChange={(e) => setEmoji(e.target.value)}
                    className="w-full border border-gray-300 rounded-lg p-2 text-xs outline-primary"
                  />
                </div>
                <div className="md:col-span-3 flex justify-end gap-2 pt-2 border-t border-gray-100">
                  <button type="button" onClick={() => setShowAddForm(false)} className="px-4 py-2 border border-gray-300 rounded-lg text-xs font-semibold text-gray-600">
                    Cancel
                  </button>
                  <button type="submit" className="px-6 py-2 bg-emerald-700 text-white rounded-lg text-xs font-bold hover:bg-emerald-800">
                    Save Product
                  </button>
                </div>
              </form>
            )}

            {/* Products Table */}
            <div className="bg-white border border-gray-200 rounded-2xl overflow-hidden shadow-sm">
              <table className="w-full text-left text-xs">
                <thead className="bg-gray-50 border-b border-gray-200 text-gray-500 font-semibold uppercase tracking-wider">
                  <tr>
                    <th className="p-4">Item</th>
                    <th className="p-4">Category</th>
                    <th className="p-4">Price (ETB)</th>
                    <th className="p-4">Stock Status</th>
                    <th className="p-4 text-right">Actions</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-100">
                  {products.map((p) => (
                    <tr key={p.id} className="hover:bg-gray-50/80">
                      <td className="p-4 font-bold text-gray-900 flex items-center gap-3">
                        <div className="w-10 h-10 rounded-lg bg-gray-100 overflow-hidden flex items-center justify-center text-xl shrink-0">
                          {p.image ? (
                            <img src={p.image} alt={p.name} className="w-full h-full object-cover" />
                          ) : (
                            p.emoji
                          )}
                        </div>
                        <div>
                          <strong className="block text-sm">{p.name}</strong>
                          <span className="text-[11px] text-gray-400 font-normal">{p.description}</span>
                        </div>
                      </td>
                      <td className="p-4">
                        <span className={`px-2.5 py-1 rounded-full text-[10px] font-extrabold ${p.category === 'Juice' ? 'bg-orange-100 text-orange-800' : 'bg-amber-100 text-amber-800'}`}>
                          {p.category}
                        </span>
                      </td>
                      <td className="p-4 font-extrabold text-gray-900 text-sm">{p.price.toFixed(1)} ETB</td>
                      <td className="p-4">
                        <span className={`px-2.5 py-1 rounded-full text-[10px] font-bold ${p.isAvailable ? 'bg-emerald-100 text-emerald-800' : 'bg-red-100 text-red-800'}`}>
                          {p.isAvailable ? 'Available' : 'Out of Stock'}
                        </span>
                      </td>
                      <td className="p-4 text-right flex items-center justify-end gap-2">
                        <button
                          onClick={() => onToggleAvailability(p.id)}
                          className={`px-3 py-1.5 rounded-lg text-xs font-bold border ${p.isAvailable ? 'border-red-300 text-red-700 bg-red-50 hover:bg-red-100' : 'border-emerald-300 text-emerald-700 bg-emerald-50 hover:bg-emerald-100'}`}
                        >
                          {p.isAvailable ? 'Mark Out of Stock' : 'Mark Available'}
                        </button>
                        <button
                          onClick={() => handleDeleteProduct(p.id)}
                          className="p-1.5 text-gray-400 hover:text-red-600 rounded-lg hover:bg-red-50"
                          title="Delete Product"
                        >
                          <Trash2 className="w-4 h-4" />
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        )}

        {/* TAB 2: Sales Analytics */}
        {activeTab === 'analytics' && (
          <div>
            <h2 className="text-xl font-bold text-gray-900 mb-2">Sales Analytics & Shift Reports (ETB)</h2>
            <p className="text-xs text-gray-500 mb-6">Real-time revenue metrics formatted in Ethiopian Birr (ETB).</p>

            <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-8">
              <div className="bg-white p-5 rounded-2xl border border-gray-200 shadow-sm">
                <span className="text-xs font-semibold text-gray-500 block">Total Shift Revenue</span>
                <strong className="text-2xl font-black text-gray-900 mt-2 block">{totalRevenue.toFixed(1)} ETB</strong>
                <span className="text-[10px] text-emerald-600 font-bold mt-1 block">{totalOrders} completed orders</span>
              </div>
              <div className="bg-white p-5 rounded-2xl border border-emerald-200 bg-emerald-50/20 shadow-sm">
                <span className="text-xs font-semibold text-emerald-800 block">Cash Sales</span>
                <strong className="text-2xl font-black text-emerald-700 mt-2 block">{cashTotal.toFixed(1)} ETB</strong>
              </div>
              <div className="bg-white p-5 rounded-2xl border border-blue-200 bg-blue-50/20 shadow-sm">
                <span className="text-xs font-semibold text-blue-800 block">Digital Transfers</span>
                <strong className="text-2xl font-black text-blue-700 mt-2 block">{transferTotal.toFixed(1)} ETB</strong>
              </div>
              <div className="bg-white p-5 rounded-2xl border border-purple-200 bg-purple-50/20 shadow-sm">
                <span className="text-xs font-semibold text-purple-800 block">Credit & Delivery</span>
                <strong className="text-2xl font-black text-purple-700 mt-2 block">{(creditTotal + deliveryTotal).toFixed(1)} ETB</strong>
              </div>
            </div>
          </div>
        )}

        {/* TAB 3: Customer Debts */}
        {activeTab === 'debts' && (
          <div>
            <h2 className="text-xl font-bold text-gray-900 mb-2">Customer Credit Debts Ledger (ETB)</h2>
            <p className="text-xs text-gray-500 mb-6">Active unpaid customer credit debts & debt recovery status.</p>

            <div className="bg-white border border-gray-200 rounded-2xl overflow-hidden shadow-sm">
              <table className="w-full text-left text-xs">
                <thead className="bg-gray-50 border-b border-gray-200 text-gray-500 font-semibold">
                  <tr>
                    <th className="p-4">Customer Name</th>
                    <th className="p-4">Note / Reason</th>
                    <th className="p-4">Amount (ETB)</th>
                    <th className="p-4">Status</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-100">
                  {debts.map((d) => (
                    <tr key={d.id} className="hover:bg-gray-50">
                      <td className="p-4 font-bold text-gray-900">{d.customerName}</td>
                      <td className="p-4 text-gray-500">{d.note}</td>
                      <td className="p-4 font-extrabold text-gray-900">{d.amount.toFixed(1)} ETB</td>
                      <td className="p-4">
                        <span className={`px-2.5 py-1 rounded-full text-[10px] font-bold ${d.isRecovered ? 'bg-emerald-100 text-emerald-800' : 'bg-amber-100 text-amber-800'}`}>
                          {d.isRecovered ? 'Recovered / Collected' : 'Unpaid Credit Debt'}
                        </span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        )}

        {/* TAB: Kitchen Production Logs & Shift Audits */}
        {activeTab === 'kitchen' && (
          <div>
            <div className="flex justify-between items-center mb-6">
              <div>
                <h2 className="text-xl font-bold text-gray-900">የኩሽና ምርት እና ማዘዣዎች (Kitchen Production & Tickets)</h2>
                <p className="text-xs text-gray-500">ኩሽና ያዘጋጃቸውን ምግቦች በሺፍት (Day shift, Night shift, Bue delivery) ይከታተሉ እና ከሽያጭ ጋር ያነጻጽሩ።</p>
              </div>
            </div>

            {/* Metrics */}
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-6">
              <div className="bg-white p-5 rounded-2xl border border-gray-200 shadow-sm flex items-center gap-4">
                <div className="w-12 h-12 rounded-xl bg-amber-50 text-amber-700 flex items-center justify-center font-bold">
                  <Utensils className="w-6 h-6" />
                </div>
                <div>
                  <span className="text-xs text-gray-500 font-bold block">የቀን ሺፍት ምግቦች (Day Shift)</span>
                  <strong className="text-2xl font-black text-gray-900">
                    {dataService.getKitchenTickets('Day shift').reduce((sum, t) => sum + t.totalQuantity, 0)}
                  </strong>
                </div>
              </div>

              <div className="bg-white p-5 rounded-2xl border border-gray-200 shadow-sm flex items-center gap-4">
                <div className="w-12 h-12 rounded-xl bg-purple-50 text-purple-700 flex items-center justify-center font-bold">
                  <ClipboardList className="w-6 h-6" />
                </div>
                <div>
                  <span className="text-xs text-gray-500 font-bold block">የማታ ሺፍት ምግቦች (Night Shift)</span>
                  <strong className="text-2xl font-black text-gray-900">
                    {dataService.getKitchenTickets('Night shift').reduce((sum, t) => sum + t.totalQuantity, 0)}
                  </strong>
                </div>
              </div>

              <div className="bg-white p-5 rounded-2xl border border-gray-200 shadow-sm flex items-center gap-4">
                <div className="w-12 h-12 rounded-xl bg-blue-50 text-blue-700 flex items-center justify-center font-bold">
                  <Truck className="w-6 h-6" />
                </div>
                <div>
                  <span className="text-xs text-gray-500 font-bold block">ቡኤ ዴሊቨሪ ምግቦች (Delivery)</span>
                  <strong className="text-2xl font-black text-gray-900">
                    {dataService.getKitchenTickets('Bue delivery').reduce((sum, t) => sum + t.totalQuantity, 0)}
                  </strong>
                </div>
              </div>
            </div>

            {/* Tickets Table */}
            <div className="bg-white rounded-2xl border border-gray-200 shadow-sm overflow-hidden">
              <div className="p-4 border-b border-gray-100 flex justify-between items-center bg-gray-50/50">
                <h3 className="font-bold text-sm text-gray-900">የተላኩ የኩሽና ቲኬቶች ዝርዝር (Dispatched Kitchen Tickets)</h3>
                <span className="text-xs text-gray-500 font-bold">ጠቅላላ {dataService.getKitchenTickets().length} ቲኬቶች</span>
              </div>
              <table className="w-full text-xs">
                <thead className="bg-gray-50 border-b border-gray-200 text-gray-500 font-bold uppercase tracking-wider">
                  <tr>
                    <th className="p-3 text-left">የቲኬት መለያ (Ticket)</th>
                    <th className="p-3 text-left">ተቀባይ ሺፍት (Route)</th>
                    <th className="p-3 text-left">የምግብ ዝርዝር (Items)</th>
                    <th className="p-3 text-center">ጠቅላላ ብዛት</th>
                    <th className="p-3 text-right">ሰዓት</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-100 font-medium">
                  {dataService.getKitchenTickets().length === 0 ? (
                    <tr>
                      <td colSpan={5} className="p-8 text-center text-gray-400">
                        ምንም የተላከ የኩሽና ቲኬት የለም። በኩሽና ገጽ ላይ ማዘዣ ሲላክ እዚህ ይመዘገባል።
                      </td>
                    </tr>
                  ) : (
                    dataService.getKitchenTickets().slice().reverse().map(t => (
                      <tr key={t.id} className="hover:bg-gray-50/50">
                        <td className="p-3 font-mono font-bold text-gray-900">#{t.id.slice(-4)}</td>
                        <td className="p-3">
                          <span className={`px-2.5 py-1 rounded-full text-[10px] font-bold ${
                            t.route === 'Day shift' ? 'bg-amber-100 text-amber-800' :
                            t.route === 'Night shift' ? 'bg-purple-100 text-purple-800' : 'bg-blue-100 text-blue-800'
                          }`}>
                            {t.route === 'Day shift' ? '☀ ቀን ሺፍት' : t.route === 'Night shift' ? '☾ ማታ ሺፍት' : '🚚 ቡኤ ዴሊቨሪ'}
                          </span>
                        </td>
                        <td className="p-3 text-gray-700">
                          {t.items.map(i => `${i.quantity}x ${i.name}`).join(', ')}
                        </td>
                        <td className="p-3 text-center font-bold text-gray-900">{t.totalQuantity}</td>
                        <td className="p-3 text-right text-gray-400 font-mono">
                          {new Date(t.createdAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                        </td>
                      </tr>
                    ))
                  )}
                </tbody>
              </table>
            </div>
          </div>
        )}

        {/* TAB: Shift Reconciliations History & Audit Ledger */}
        {activeTab === 'reconciliations' && (
          <div>
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-6">
              <div>
                <h2 className="text-xl font-bold text-gray-900 flex items-center gap-2">
                  <FileSpreadsheet className="w-5 h-5 text-purple-700" />
                  የሺፍት ሪፖርቶችና የሂሳብ ርክክብ (Shift Reconciliations History)
                </h2>
                <p className="text-xs text-gray-500">
                  በካሺየር የተዘጉ እና በባለቤቱ በእጅ የገቡ የሺፍት ቆጠራዎች፣ ወጪዎችና የተረከበ ጥሬ ገንዘብ ዝርዝር።
                </p>
              </div>

              <div className="flex items-center gap-2">
                {onOpenManualRecon && (
                  <button
                    onClick={onOpenManualRecon}
                    className="px-4 py-2 bg-gradient-to-r from-purple-700 to-indigo-700 hover:from-purple-800 hover:to-indigo-800 text-white text-xs font-bold rounded-xl shadow-md flex items-center gap-2 transition"
                  >
                    <Plus className="w-4 h-4" /> አዲስ የሺፍት ሪፖርት ሙላ (Manual Entry)
                  </button>
                )}
              </div>
            </div>

            {/* Filter pills */}
            <div className="flex items-center justify-between gap-2 mb-4 bg-white p-3 rounded-2xl border border-gray-200 shadow-sm">
              <div className="flex items-center gap-2">
                <span className="text-xs font-bold text-gray-500 mr-1">ማጣሪያ (Filter):</span>
                <button
                  onClick={() => setReconFilter('all')}
                  className={`px-3 py-1 rounded-lg text-xs font-bold transition ${
                    reconFilter === 'all' ? 'bg-purple-700 text-white' : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                  }`}
                >
                  ሁሉም ({reconciliations.length})
                </button>
                <button
                  onClick={() => setReconFilter('day')}
                  className={`px-3 py-1 rounded-lg text-xs font-bold transition ${
                    reconFilter === 'day' ? 'bg-amber-600 text-white' : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                  }`}
                >
                  ቀን ሺፍት ({reconciliations.filter(r => r.shiftType === 'day').length})
                </button>
                <button
                  onClick={() => setReconFilter('night')}
                  className={`px-3 py-1 rounded-lg text-xs font-bold transition ${
                    reconFilter === 'night' ? 'bg-indigo-600 text-white' : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                  }`}
                >
                  ማታ ሺፍት ({reconciliations.filter(r => r.shiftType === 'night').length})
                </button>
              </div>

              {isLoadingRecons && (
                <span className="text-xs text-gray-400 flex items-center gap-1">
                  <RefreshCw className="w-3.5 h-3.5 animate-spin" /> በማደስ ላይ...
                </span>
              )}
            </div>

            {/* Reconciliation List Cards */}
            {reconciliations.length === 0 ? (
              <div className="bg-white p-12 rounded-2xl border border-gray-200 text-center shadow-sm">
                <div className="w-16 h-16 bg-purple-50 text-purple-600 rounded-2xl flex items-center justify-center mx-auto mb-3">
                  <FileSpreadsheet className="w-8 h-8" />
                </div>
                <h3 className="text-base font-bold text-gray-900 mb-1">ምንም የተመዘገበ የሺፍት ሪፖርት የለም</h3>
                <p className="text-xs text-gray-500 max-w-md mx-auto mb-4">
                  የቀን ወይም የማታ ሺፍት ሲዘጋ ወይም በባለቤቱ &quot;አዲስ የሺፍት ሪፖርት ሙላ&quot; ተብሎ በእጅ ሲገባ እዚህ ይመዘገባል።
                </p>
                {onOpenManualRecon && (
                  <button
                    onClick={onOpenManualRecon}
                    className="px-5 py-2.5 bg-purple-700 hover:bg-purple-800 text-white text-xs font-bold rounded-xl shadow-md inline-flex items-center gap-2"
                  >
                    <Plus className="w-4 h-4" /> የመጀመሪያ ሪፖርት አሁን ይመዝግቡ
                  </button>
                )}
              </div>
            ) : (
              <div className="space-y-4">
                {reconciliations
                  .filter(r => (reconFilter === 'all' ? true : r.shiftType === reconFilter))
                  .map((recon) => {
                    const isExpanded = expandedReconId === recon.id;
                    const dateDisplay = recon.shiftDate || recon.closedAt?.slice(0, 10) || 'Today';

                    return (
                      <div
                        key={recon.id}
                        className="bg-white rounded-2xl border border-gray-200 shadow-sm overflow-hidden transition-all hover:border-gray-300"
                      >
                        {/* Header Row */}
                        <div className="p-5 flex flex-col md:flex-row md:items-center justify-between gap-4 bg-gray-50/50">
                          <div className="flex items-start sm:items-center gap-3.5">
                            <div className={`w-12 h-12 rounded-xl flex items-center justify-center font-bold shrink-0 ${
                              recon.shiftType === 'day' ? 'bg-amber-100 text-amber-800' : 'bg-indigo-100 text-indigo-800'
                            }`}>
                              {recon.shiftType === 'day' ? <Sun className="w-6 h-6" /> : <Moon className="w-6 h-6" />}
                            </div>

                            <div>
                              <div className="flex items-center gap-2 flex-wrap">
                                <h4 className="font-extrabold text-sm sm:text-base text-gray-900">
                                  {dateDisplay} • {recon.shiftType === 'day' ? 'ቀን ሺፍት (Day Shift)' : 'ማታ ሺፍት (Night Shift)'}
                                </h4>
                                <span className={`px-2 py-0.5 rounded-full text-[10px] font-bold uppercase ${
                                  recon.entryMode === 'manual'
                                    ? 'bg-purple-100 text-purple-800 border border-purple-200'
                                    : 'bg-emerald-100 text-emerald-800 border border-emerald-200'
                                }`}>
                                  {recon.entryMode === 'manual' ? 'Manual Admin Entry' : 'Live POS Shift'}
                                </span>
                              </div>
                              <p className="text-xs text-gray-500 mt-0.5">
                                ካሺየር: <strong className="text-gray-700">{recon.cashierName}</strong> • የተዘጋበት ሰዓት: {new Date(recon.closedAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                              </p>
                            </div>
                          </div>

                          {/* Key Financial KPIs */}
                          <div className="flex items-center gap-4 sm:gap-6 flex-wrap">
                            <div className="text-right">
                              <span className="text-[10px] text-gray-400 font-bold block uppercase">ጠቅላላ ገቢ</span>
                              <strong className="text-sm font-extrabold text-gray-800">
                                {recon.grossRevenue?.toLocaleString()} ETB
                              </strong>
                            </div>

                            <div className="text-right bg-emerald-50 px-3.5 py-1.5 rounded-xl border border-emerald-200">
                              <span className="text-[10px] text-emerald-700 font-bold block uppercase">የተረከበ ጥሬ ገንዘብ</span>
                              <strong className="text-base font-black text-emerald-700">
                                {recon.netCashToOwner?.toLocaleString()} ETB
                              </strong>
                            </div>

                            <button
                              onClick={() => setExpandedReconId(isExpanded ? null : recon.id)}
                              className="px-3 py-1.5 bg-gray-100 hover:bg-gray-200 text-gray-700 rounded-xl text-xs font-bold flex items-center gap-1.5 transition"
                            >
                              {isExpanded ? (
                                <>ዝርዝር ደብቅ <ChevronUp className="w-4 h-4" /></>
                              ) : (
                                <>ሙሉ ዝርዝር <ChevronDown className="w-4 h-4" /></>
                              )}
                            </button>
                          </div>
                        </div>

                        {/* Quick Metrics Bar */}
                        <div className="px-5 py-3 border-t border-gray-100 grid grid-cols-2 sm:grid-cols-5 gap-2 text-xs text-gray-600 bg-white">
                          <div>
                            <span className="text-[10px] text-gray-400 block">ጥሬ ገንዘብ (Cash):</span>
                            <strong>{recon.cashSales?.toLocaleString()} ETB</strong>
                          </div>
                          <div>
                            <span className="text-[10px] text-gray-400 block">ትራንስፈር (Transfer):</span>
                            <strong>{recon.transferSales?.toLocaleString()} ETB</strong>
                          </div>
                          <div>
                            <span className="text-[10px] text-gray-400 block">የጁስ ኩባያ (Cups Sold):</span>
                            <strong>{recon.calculatedCupsSold || recon.tabletCupsSold || 0} Cups</strong>
                          </div>
                          <div>
                            <span className="text-[10px] text-gray-400 block">የሺፍት ወጪዎች (Expenses):</span>
                            <strong className="text-red-600">-{recon.totalExpenses?.toLocaleString()} ETB</strong>
                          </div>
                          <div>
                            <span className="text-[10px] text-gray-400 block">የተሰበሰበ አዳሪ (Recovered):</span>
                            <strong className="text-emerald-600">+{recon.totalRecoveredDebts?.toLocaleString()} ETB</strong>
                          </div>
                        </div>

                        {/* EXPANDABLE FULL 11-SECTION ACCORDION */}
                        {isExpanded && (
                          <div className="p-5 border-t border-gray-200 bg-gray-50/80 space-y-5 animate-fadeIn">
                            
                            {/* Section 1: Sales Summary Breakdown */}
                            <div className="bg-white p-4 rounded-xl border border-gray-200 shadow-sm">
                              <h5 className="text-xs font-bold text-gray-800 uppercase tracking-wider mb-2 flex items-center gap-1.5">
                                <DollarSign className="w-4 h-4 text-emerald-600" /> 1. የሽያጭ ክፍፍል ዝርዝር (Sales Breakdown)
                              </h5>
                              <div className="grid grid-cols-2 sm:grid-cols-5 gap-2 text-xs">
                                <div className="p-2 bg-gray-50 rounded-lg">
                                  <span className="text-[10px] text-gray-500 block">ጥሬ ገንዘብ (Cash)</span>
                                  <strong className="text-emerald-700">{recon.cashSales?.toLocaleString()} ETB</strong>
                                </div>
                                <div className="p-2 bg-gray-50 rounded-lg">
                                  <span className="text-[10px] text-gray-500 block">ባንክ / ቴሌብር (Transfer)</span>
                                  <strong className="text-cyan-700">{recon.transferSales?.toLocaleString()} ETB</strong>
                                </div>
                                <div className="p-2 bg-gray-50 rounded-lg">
                                  <span className="text-[10px] text-gray-500 block">አዳሪ / ብድር (Credit)</span>
                                  <strong className="text-amber-700">{recon.creditSales?.toLocaleString()} ETB</strong>
                                </div>
                                <div className="p-2 bg-gray-50 rounded-lg">
                                  <span className="text-[10px] text-gray-500 block">ዴሊቨሪ (Delivery)</span>
                                  <strong className="text-purple-700">{recon.deliverySales?.toLocaleString()} ETB</strong>
                                </div>
                                <div className="p-2 bg-gray-50 rounded-lg">
                                  <span className="text-[10px] text-gray-500 block">ጉርሻ / ቲፕ (Tip)</span>
                                  <strong>{recon.tipSales?.toLocaleString()} ETB</strong>
                                </div>
                              </div>
                            </div>

                            {/* Section 2 & 3: Juice Inventory & Flavors */}
                            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                              <div className="bg-white p-4 rounded-xl border border-gray-200 shadow-sm">
                                <h5 className="text-xs font-bold text-gray-800 uppercase tracking-wider mb-2 flex items-center gap-1.5">
                                  <Coffee className="w-4 h-4 text-amber-600" /> 2. የጁስ ኩባያ ቆጠራ (Cup Inventory)
                                </h5>
                                <div className="grid grid-cols-3 gap-2 text-xs text-center">
                                  <div className="p-2 bg-gray-50 rounded-lg">
                                    <span className="text-[10px] text-gray-500 block">መክፈቻ (Opening)</span>
                                    <strong className="text-gray-800">{recon.openingCups}</strong>
                                  </div>
                                  <div className="p-2 bg-gray-50 rounded-lg">
                                    <span className="text-[10px] text-gray-500 block">ተጨማሪ (Added)</span>
                                    <strong className="text-gray-800">+{recon.addedCups}</strong>
                                  </div>
                                  <div className="p-2 bg-gray-50 rounded-lg">
                                    <span className="text-[10px] text-gray-500 block">ቀሪ (Leftover)</span>
                                    <strong className="text-amber-700">{recon.leftoverCups}</strong>
                                  </div>
                                </div>
                                <div className="mt-2 text-xs font-bold text-amber-800 bg-amber-50 p-2 rounded-lg text-center">
                                  የተሸጠ ኩባያ: {recon.calculatedCupsSold} ({(recon.calculatedCupsSold * 170).toLocaleString()} ETB)
                                </div>
                              </div>

                              {/* Juice Flavor Breakdown */}
                              {recon.juiceBreakdown && recon.juiceBreakdown.length > 0 && (
                                <div className="bg-white p-4 rounded-xl border border-gray-200 shadow-sm">
                                  <h5 className="text-xs font-bold text-gray-800 uppercase tracking-wider mb-2">
                                    🍹 3. የተሸጡ ጁሶች በዓይነት
                                  </h5>
                                  <div className="grid grid-cols-2 gap-1.5 text-xs max-h-28 overflow-y-auto">
                                    {recon.juiceBreakdown.filter(j => j.sold > 0).map((j, idx) => (
                                      <div key={idx} className="flex items-center justify-between p-1.5 bg-gray-50 rounded">
                                        <span>{j.emoji} {j.name}</span>
                                        <strong className="text-amber-700">{j.sold}</strong>
                                      </div>
                                    ))}
                                  </div>
                                </div>
                              )}
                            </div>

                            {/* Section 4 & 5: Food Box Inventory & Food Sold Breakdown */}
                            {recon.foodBoxInventory && recon.foodBoxInventory.length > 0 && (
                              <div className="bg-white p-4 rounded-xl border border-gray-200 shadow-sm">
                                <h5 className="text-xs font-bold text-gray-800 uppercase tracking-wider mb-2 flex items-center gap-1.5">
                                  <Utensils className="w-4 h-4 text-orange-600" /> 4. የምግብ ሣጥንና የሽያጭ ቆጠራ (Food Breakdown)
                                </h5>
                                <div className="overflow-x-auto">
                                  <table className="w-full text-left text-xs">
                                    <thead>
                                      <tr className="border-b border-gray-200 text-gray-500 font-semibold">
                                        <th className="pb-1.5">የምግብ ዓይነት</th>
                                        <th className="pb-1.5 text-center">መክፈቻ</th>
                                        <th className="pb-1.5 text-center">ቀሪ</th>
                                        <th className="pb-1.5 text-center text-amber-700">ተበልቷል</th>
                                        <th className="pb-1.5 text-center text-emerald-700">አስተናጋጅ የሸጠችው</th>
                                      </tr>
                                    </thead>
                                    <tbody className="divide-y divide-gray-100">
                                      {recon.foodBoxInventory
                                        .filter(f => f.opening > 0 || f.leftover > 0 || f.consumed > 0)
                                        .map((f, idx) => {
                                          const soldItem = recon.foodSoldBreakdown?.find(s => s.name === f.name);
                                          return (
                                            <tr key={idx}>
                                              <td className="py-1.5 font-medium text-gray-800">{f.emoji} {f.name}</td>
                                              <td className="py-1.5 text-center">{f.opening}</td>
                                              <td className="py-1.5 text-center">{f.leftover}</td>
                                              <td className="py-1.5 text-center font-bold text-amber-700">{f.consumed}</td>
                                              <td className="py-1.5 text-center font-bold text-emerald-700">{soldItem?.sold || 0}</td>
                                            </tr>
                                          );
                                        })}
                                    </tbody>
                                  </table>
                                </div>
                              </div>
                            )}

                            {/* Section 6 & 7: Transfers & Expenses */}
                            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                              {/* Transfers */}
                              <div className="bg-white p-4 rounded-xl border border-gray-200 shadow-sm">
                                <h5 className="text-xs font-bold text-gray-800 uppercase tracking-wider mb-2 flex items-center gap-1.5">
                                  <Smartphone className="w-4 h-4 text-cyan-600" /> 6. የባንክና ቴሌብር ዝርዝር ({recon.transferRecords?.length || 0})
                                </h5>
                                {recon.transferRecords && recon.transferRecords.length > 0 ? (
                                  <div className="space-y-1.5 max-h-32 overflow-y-auto">
                                    {recon.transferRecords.map((t, idx) => (
                                      <div key={idx} className="flex items-center justify-between p-2 bg-gray-50 rounded-lg text-xs">
                                        <div>
                                          <strong>{t.senderName || 'Anonymous'}</strong>
                                          <span className="text-[10px] text-gray-500 block">{t.note}</span>
                                        </div>
                                        <strong className="text-cyan-700 font-bold">{t.amount?.toLocaleString()} ETB</strong>
                                      </div>
                                    ))}
                                  </div>
                                ) : (
                                  <p className="text-xs text-gray-400 italic">ዝርዝር ትራንስፈር አልተመዘገበም</p>
                                )}
                              </div>

                              {/* Expenses */}
                              <div className="bg-white p-4 rounded-xl border border-gray-200 shadow-sm">
                                <h5 className="text-xs font-bold text-gray-800 uppercase tracking-wider mb-2 flex items-center gap-1.5">
                                  <Receipt className="w-4 h-4 text-red-600" /> 7. የሺፍት ወጪዎች ({recon.expenses?.length || 0})
                                </h5>
                                {recon.expenses && recon.expenses.length > 0 ? (
                                  <div className="space-y-1.5 max-h-32 overflow-y-auto">
                                    {recon.expenses.map((e, idx) => (
                                      <div key={idx} className="flex items-center justify-between p-2 bg-gray-50 rounded-lg text-xs">
                                        <div>
                                          <strong>{e.description || e.category}</strong>
                                          <span className="text-[10px] text-gray-500 block">{e.category}</span>
                                        </div>
                                        <strong className="text-red-700 font-bold">-{e.amount?.toLocaleString()} ETB</strong>
                                      </div>
                                    ))}
                                  </div>
                                ) : (
                                  <p className="text-xs text-gray-400 italic">ምንም ወጪ አልተመዘገበም</p>
                                )}
                              </div>
                            </div>

                            {/* Section 8 & 9: Debts Created & Recovered */}
                            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                              {/* Pending Debts Created */}
                              <div className="bg-white p-4 rounded-xl border border-gray-200 shadow-sm">
                                <h5 className="text-xs font-bold text-gray-800 uppercase tracking-wider mb-2 flex items-center gap-1.5">
                                  <CreditCard className="w-4 h-4 text-amber-600" /> 8. አዳዲስ የተፈጠሩ አዳሪዎች ({recon.pendingPayments?.length || 0})
                                </h5>
                                {recon.pendingPayments && recon.pendingPayments.length > 0 ? (
                                  <div className="space-y-1.5 max-h-32 overflow-y-auto">
                                    {recon.pendingPayments.map((p, idx) => (
                                      <div key={idx} className="flex items-center justify-between p-2 bg-amber-50/50 rounded-lg text-xs">
                                        <div>
                                          <strong>{p.customerName}</strong>
                                          <span className="text-[10px] text-gray-500 block">{p.note}</span>
                                        </div>
                                        <strong className="text-amber-800 font-bold">{p.amount?.toLocaleString()} ETB</strong>
                                      </div>
                                    ))}
                                  </div>
                                ) : (
                                  <p className="text-xs text-gray-400 italic">ምንም አዲስ አዳሪ አልተመዘገበም</p>
                                )}
                              </div>

                              {/* Recovered Debts */}
                              <div className="bg-white p-4 rounded-xl border border-gray-200 shadow-sm">
                                <h5 className="text-xs font-bold text-gray-800 uppercase tracking-wider mb-2 flex items-center gap-1.5">
                                  <CheckCircle2 className="w-4 h-4 text-emerald-600" /> 9. የተሰበሰቡ የቆዩ አዳሪዎች ({recon.recoveredPayments?.length || recon.recoveredDebts?.length || 0})
                                </h5>
                                {(recon.recoveredPayments && recon.recoveredPayments.length > 0) || (recon.recoveredDebts && recon.recoveredDebts.length > 0) ? (
                                  <div className="space-y-1.5 max-h-32 overflow-y-auto">
                                    {(recon.recoveredPayments || []).map((r, idx) => (
                                      <div key={idx} className="flex items-center justify-between p-2 bg-emerald-50/50 rounded-lg text-xs">
                                        <span>{r.customerName}</span>
                                        <strong className="text-emerald-800 font-bold">+{r.amount?.toLocaleString()} ETB</strong>
                                      </div>
                                    ))}
                                  </div>
                                ) : (
                                  <p className="text-xs text-gray-400 italic">የተሰበሰበ የቆየ አዳሪ የለም</p>
                                )}
                              </div>
                            </div>

                            {/* Section 10: Shift Notes */}
                            {recon.shiftNotes && (
                              <div className="p-3 bg-white rounded-xl border border-gray-200 text-xs">
                                <span className="text-[10px] text-gray-500 font-bold uppercase block mb-1">የሺፍቱ ማስታወሻ:</span>
                                <p className="text-gray-700 italic">{recon.shiftNotes}</p>
                              </div>
                            )}

                          </div>
                        )}

                      </div>
                    );
                  })}
              </div>
            )}
          </div>
        )}

        {/* TAB 4: Supabase BaaS Integration & Full SQL Schema */}
        {activeTab === 'supabase' && (
          <div className="max-w-4xl">
            <div className="bg-white p-6 rounded-2xl border border-gray-200 shadow-sm mb-6">
              <div className="flex items-center justify-between mb-4">
                <div className="flex items-center gap-3">
                  <Database className="w-6 h-6 text-emerald-600" />
                  <div>
                    <h2 className="text-lg font-bold text-gray-900">Supabase Backend as a Service (BaaS)</h2>
                    <p className="text-xs text-gray-500">PostgreSQL Cloud Database Integration</p>
                  </div>
                </div>
                <span className={`px-3 py-1 rounded-full text-xs font-bold ${isSupabaseConfigured ? 'bg-emerald-100 text-emerald-800' : 'bg-amber-100 text-amber-800'}`}>
                  {isSupabaseConfigured ? 'Connected to Supabase' : 'Running in Dual-Mode (Local + Supabase Ready)'}
                </span>
              </div>

              <p className="text-xs text-gray-600 leading-relaxed mb-4">
                Maraki POS is fully wired with Supabase BaaS! You can run it out of the box with built-in instant local state, or connect your Supabase database by setting environment variables in <code className="bg-gray-100 px-1 py-0.5 rounded text-red-600 font-mono text-[11px]">.env.local</code>.
              </p>

              <div className="bg-gray-900 text-gray-100 p-4 rounded-xl font-mono text-xs mb-4">
                <div className="text-gray-400 font-sans text-[10px] mb-2 uppercase tracking-wider"># Add to .env.local</div>
                <div>NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co</div>
                <div>NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key-here</div>
              </div>

              <div className="p-4 bg-emerald-50 border border-emerald-200 rounded-xl text-xs text-emerald-900 mb-6">
                <CheckCircle2 className="w-4 h-4 text-emerald-600 inline mr-2" />
                The <code className="font-mono font-bold">supabase_schema.sql</code> file is available below and in your project root! Open your Supabase Dashboard &gt; SQL Editor, paste the contents, and click <strong>Run</strong> to set up all tables and initial products automatically.
              </div>

              <div className="flex items-center justify-between mb-2">
                <h3 className="text-xs font-bold text-gray-700 uppercase tracking-wider">Complete Supabase SQL Setup Script</h3>
                <button
                  onClick={copySql}
                  className="px-3 py-1.5 bg-gray-800 text-white rounded-lg text-xs font-semibold hover:bg-gray-700 flex items-center gap-1.5"
                >
                  {copied ? <Check className="w-3.5 h-3.5 text-emerald-400" /> : <Copy className="w-3.5 h-3.5" />}
                  {copied ? 'Copied SQL!' : 'Copy SQL Schema'}
                </button>
              </div>

              <pre className="bg-gray-900 text-emerald-400 p-4 rounded-xl font-mono text-[11px] overflow-x-auto max-h-80 border border-gray-800">
                {sqlCode}
              </pre>
            </div>
          </div>
        )}
      </div>
    </main>
  );
}
