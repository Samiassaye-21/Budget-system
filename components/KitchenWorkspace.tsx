'use client';

import React, { useState, useMemo } from 'react';
import { Search, Plus, Minus, Check, Sparkles, ClipboardList, Truck, ChevronRight } from 'lucide-react';
import { Product, OrderItem, KitchenRoute, KitchenTicket } from '../types/pos';
import { dataService } from '../lib/dataService';

interface KitchenWorkspaceProps {
  products: Product[];
  onBack: () => void;
  onTicketSent?: (ticket: KitchenTicket) => void;
}

export function KitchenWorkspace({ products, onBack, onTicketSent }: KitchenWorkspaceProps) {
  const [route, setRoute] = useState<KitchenRoute>('Day shift');
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [selectedItems, setSelectedItems] = useState<OrderItem[]>([]);
  const [ticketSent, setTicketSent] = useState<boolean>(false);
  const [lastTicketId, setLastTicketId] = useState<string>('');

  const foodProducts = useMemo(() => {
    return products.filter(
      p => p.category === 'Food' && p.name.toLowerCase().includes(searchQuery.toLowerCase())
    );
  }, [products, searchQuery]);

  const handleAddItem = (item: Product) => {
    setSelectedItems(prev => {
      const found = prev.find(line => line.id === item.id || line.name === item.name);
      return found
        ? prev.map(line => line.id === item.id || line.name === item.name ? { ...line, quantity: line.quantity + 1 } : line)
        : [...prev, { ...item, quantity: 1 }];
    });
  };

  const handleChangeQuantity = (name: string, delta: number) => {
    setSelectedItems(prev =>
      prev
        .map(item => (item.name === name ? { ...item, quantity: item.quantity + delta } : item))
        .filter(item => item.quantity > 0)
    );
  };

  const totalItemsCount = selectedItems.reduce((sum, i) => sum + i.quantity, 0);

  const handleSendTicket = async () => {
    if (selectedItems.length === 0) return;
    const ticketId = `k-ticket-${Date.now()}`;
    const newTicket: KitchenTicket = {
      id: ticketId,
      route,
      items: [...selectedItems],
      totalQuantity: totalItemsCount,
      createdAt: new Date().toISOString()
    };
    await dataService.saveKitchenTicket(newTicket);
    if (onTicketSent) {
      onTicketSent(newTicket);
    }
    setLastTicketId(ticketId.slice(-4));
    setTicketSent(true);
  };

  if (ticketSent) {
    return (
      <main className="kitchen-shell">
        <section className="ticket-success">
          <div className="success-mark">
            <Check className="w-8 h-8" />
          </div>
          <p className="eyebrow">ቲኬት ተልኳል (TICKET SENT)</p>
          <h1>የኩሽና ቲኬት ዝግጁ ነው</h1>
          <p>የምግብ ማዘዣ ቲኬትዎ ለ <strong>{route === 'Day shift' ? 'የቀን ሺፍት' : route === 'Night shift' ? 'የማታ ሺፍት' : 'ቡኤ ዴሊቨሪ'}</strong> ተልኳል።</p>
          <div className="ticket-number">KITCHEN #{lastTicketId || String(Date.now()).slice(-4)}</div>
          <button
            className="primary-wide cursor-pointer"
            onClick={() => {
              setSelectedItems([]);
              setTicketSent(false);
            }}
          >
            ሌላ የኩሽና ቲኬት ፍጠር <Plus className="w-4 h-4" />
          </button>
          <button className="back-link center block mt-4" onClick={onBack}>
            ወደ የስራ ቦታ መረጣ ተመለስ
          </button>
        </section>
      </main>
    );
  }

  return (
    <main className="kitchen-shell">
      <header className="kitchen-header">
        <button className="back-link" onClick={onBack}>
          ← ወደ የስራ ቦታ መረጣ
        </button>
        <div className="brand flex items-center gap-2">
          <img src="/logo.jpg" alt="Maraki Logo" className="w-9 h-9 rounded-full object-cover border border-amber-300" />
          <div>
            <strong>ማራኪ<span>POS</span></strong>
            <small>የኩሽና ማዘዣዎች (KITCHEN TICKETS)</small>
          </div>
        </div>
        <div className="kitchen-status">
          <span className="online-dot" /> ኩሽና ማሳወቂያ ጣቢያ
        </div>
      </header>

      <div className="kitchen-content">
        <section className="kitchen-menu">
          <div className="section-heading">
            <div>
              <p className="eyebrow">የምግብ ዝርዝር / {foodProducts.length} እቃዎች</p>
              <h1>ማዘዣ ወደ ኩሽና ላክ</h1>
              <p className="muted">ተቀባይ ሺፍት ይምረጡ፣ ከዚያ እቃዎችን ይምረጡ።</p>
            </div>
            <div className="desktop-search">
              <Search className="w-4 h-4 text-gray-400" />
              <input
                placeholder="የምግብ ዝርዝር ይፈልጉ..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
              />
            </div>
          </div>

          <div className="route-picker">
            <span>ተቀባዩ ማን ነው?</span>
            {(['Day shift', 'Night shift', 'Bue delivery'] as KitchenRoute[]).map(item => (
              <button
                key={item}
                className={route === item ? 'selected' : ''}
                onClick={() => setRoute(item)}
              >
                {item === 'Bue delivery' ? <Truck className="w-4 h-4" /> : <ClipboardList className="w-4 h-4" />}
                {item === 'Day shift' ? 'ቀን ሺፍት' : item === 'Night shift' ? 'ማታ ሺፍት' : 'ቡኤ ዴሊቨሪ'}
              </button>
            ))}
          </div>

          <div className="kitchen-grid">
            {foodProducts.map(product => (
              <article className="kitchen-product" key={product.id || product.name}>
                <div className={`product-image ${product.tone} overflow-hidden`}>
                  {product.image ? (
                    <img src={product.image} alt={product.name} className="w-full h-full object-cover" />
                  ) : (
                    <span>{product.emoji}</span>
                  )}
                </div>
                <div>
                  <h3>{product.name}</h3>
                  <p>{product.description}</p>
                  <strong>{product.price.toFixed(0)} <small className="currency">ETB</small></strong>
                </div>
                <button className="add-button cursor-pointer font-bold" onClick={() => handleAddItem(product)}>
                  <Plus className="w-3.5 h-3.5" /> ጨምር
                </button>
              </article>
            ))}
          </div>
        </section>

        <aside className="ticket-panel">
          <p className="eyebrow">አዲስ የኩሽና ቲኬት</p>
          <h2>{route === 'Day shift' ? 'ቀን ሺፍት' : route === 'Night shift' ? 'ማታ ሺፍት' : 'ቡኤ ዴሊቨሪ'}</h2>
          <div className="ticket-route">
            <span>ROUTE</span>
            <strong>{route === 'Bue delivery' ? 'የዴሊቨሪ ርክክብ' : 'የሺፍት ርክክብ'}</strong>
          </div>

          <div className="ticket-items">
            {selectedItems.length === 0 ? (
              <div className="empty-ticket">
                <ClipboardList className="w-8 h-8 text-gray-300 mx-auto mb-2" />
                <p>ምንም የተመረጠ ምግብ የለም</p>
                <small>ከምግብ ዝርዝሩ ላይ ጨምር የሚለውን ይጫኑ</small>
              </div>
            ) : (
              selectedItems.map(item => (
                <div className="ticket-item" key={item.id || item.name}>
                  <span>{item.emoji}</span>
                  <div>
                    <strong>{item.name}</strong>
                    <small>{item.price.toFixed(0)} ETB እያንዳንዱ</small>
                  </div>
                  <div className="quantity">
                    <button onClick={() => handleChangeQuantity(item.name, -1)}><Minus className="w-3 h-3" /></button>
                    <b>{item.quantity}</b>
                    <button onClick={() => handleChangeQuantity(item.name, 1)}><Plus className="w-3 h-3" /></button>
                  </div>
                </div>
              ))
            )}
          </div>

          <div className="ticket-total">
            <span>ጠቅላላ ብዛት</span>
            <strong>{totalItemsCount}</strong>
          </div>

          <button
            className="fire-button cursor-pointer font-bold"
            disabled={selectedItems.length === 0}
            onClick={handleSendTicket}
          >
            <Sparkles className="w-4 h-4" /> የኩሽና ቲኬት ላክ <ChevronRight className="w-4 h-4" />
          </button>
        </aside>
      </div>
    </main>
  );
}
