import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BusinessDashboardScreen extends StatefulWidget {
  const BusinessDashboardScreen({super.key});
  @override
  State<BusinessDashboardScreen> createState() => _BusinessDashboardScreenState();
}

class _BusinessDashboardScreenState extends State<BusinessDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  @override
  void initState() { super.initState(); _tab = TabController(length: 3, vsync: this); }
  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Business', style: GoogleFonts.inter(fontWeight: FontWeight.w700))),
      body: Column(children: [
        // Performance Cards
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: const [
              _PerfCard(label: 'Total Orders', value: '48', icon: Icons.shopping_bag_outlined, color: Color(0xFF4338CA)),
              _PerfCard(label: 'CRM Leads', value: '23', icon: Icons.people_alt_outlined, color: Color(0xFF10B981)),
              _PerfCard(label: 'Revenue', value: '₦124k', icon: Icons.payments_outlined, color: Color(0xFFF59E0B)),
              _PerfCard(label: 'Visibility', value: '72%', icon: Icons.visibility_outlined, color: Color(0xFF6366F1)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TabBar(
          controller: _tab,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
          indicatorColor: const Color(0xFF4338CA),
          labelColor: const Color(0xFF4338CA),
          unselectedLabelColor: const Color(0xFF6B7280),
          tabs: const [Tab(text: 'Catalog'), Tab(text: 'Marketing'), Tab(text: 'Sales')],
        ),
        Expanded(child: TabBarView(controller: _tab, children: [
          // Catalog
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 4,
            itemBuilder: (_, i) => _ProductListTile(
              name: ['Homemade Bread', 'Croissants', 'Sourdough', 'Muffin Pack'][i],
              price: ['₦1,200', '₦800', '₦2,500', '₦600'][i],
              stock: ['In Stock', 'In Stock', 'Low Stock', 'Out of Stock'][i],
            ),
          ),
          Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.campaign_outlined, size: 56, color: Color(0xFFE5E7EB)),
            const SizedBox(height: 12),
            Text('Marketing tools coming soon', style: GoogleFonts.inter(color: const Color(0xFF6B7280))),
          ])),
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 4,
            itemBuilder: (_, i) => _InvoiceTile(
              client: ['Emeka & Sons', 'Mrs. Adaobi', 'Bola Enterprises', 'Kunle Farms'][i],
              amount: ['₦45,000', '₦12,000', '₦87,500', '₦23,000'][i],
              status: ['Paid', 'Pending', 'Paid', 'Overdue'][i],
            ),
          ),
        ])),
      ]),
    );
  }
}

class _PerfCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _PerfCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120, margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 20),
        const Spacer(),
        Text(value, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: color.withValues(alpha: 0.8))),
      ]),
    );
  }
}

class _ProductListTile extends StatelessWidget {
  final String name, price, stock;
  const _ProductListTile({required this.name, required this.price, required this.stock});

  @override
  Widget build(BuildContext context) {
    final isLow = stock == 'Low Stock';
    final isOut = stock == 'Out of Stock';
    final stockColor = isOut ? Colors.red : isLow ? const Color(0xFFF59E0B) : const Color(0xFF10B981);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Row(children: [
        Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF6B7280), size: 22)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          Text(price, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF4338CA), fontWeight: FontWeight.w600)),
        ])),
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: stockColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)), child: Text(stock, style: GoogleFonts.inter(fontSize: 11, color: stockColor, fontWeight: FontWeight.w600))),
      ]),
    );
  }
}

class _InvoiceTile extends StatelessWidget {
  final String client, amount, status;
  const _InvoiceTile({required this.client, required this.amount, required this.status});

  @override
  Widget build(BuildContext context) {
    final isPaid = status == 'Paid';
    final isOverdue = status == 'Overdue';
    final color = isOverdue ? Colors.red : isPaid ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Row(children: [
        const Icon(Icons.receipt_long_outlined, color: Color(0xFF6B7280)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(client, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          Text(amount, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF111827))),
        ])),
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)), child: Text(status, style: GoogleFonts.inter(fontSize: 11, color: color, fontWeight: FontWeight.w600))),
      ]),
    );
  }
}
