import 'package:flutter/material.dart';
import 'agent_service.dart';

class AgentPanel extends StatefulWidget {
  final void Function(PlaceRecommendation place) onPlaceSelected;

  const AgentPanel({super.key, required this.onPlaceSelected});

  @override
  State<AgentPanel> createState() => _AgentPanelState();
}

class _AgentPanelState extends State<AgentPanel> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final List<AgentMessage> _history = [];
  final List<_ChatBubble> _bubbles = [];
  List<PlaceRecommendation>? _recommendations;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _bubbles.add(const _ChatBubble(
      isAgent: true,
      text: '¡Hola! Soy tu guía de Durango 🦂\n¿Qué tipo de lugar estás buscando?\n(gastronomía, turismo, artesanías, actividades...)',
    ));
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _loading) return;

    _input.clear();
    setState(() {
      _bubbles.add(_ChatBubble(isAgent: false, text: text));
      _recommendations = null;
      _loading = true;
    });
    _scrollToBottom();

    try {
      final response = await AgentService.sendMessage(text, _history);

      _history.add(AgentMessage(role: 'user', content: text));
      _history.add(AgentMessage(role: 'assistant', content: response.text));

      setState(() {
        _bubbles.add(_ChatBubble(isAgent: true, text: response.text));
        if (response.type == 'recommendations') {
          _recommendations = response.places;
        }
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _bubbles.add(_ChatBubble(
          isAgent: true,
          text: 'No pude conectar con el agente.\nVerifica que el servidor esté corriendo y revisa la IP en agent_service.dart.\nError: $e',
        ));
        _loading = false;
      });
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      minChildSize: 0.35,
      expand: false,
      builder: (context, _) => Column(
        children: [
          _buildHandle(),
          _buildHeader(context),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(12),
              itemCount: _bubbles.length,
              itemBuilder: (_, i) => _bubbles[i],
            ),
          ),
          if (_loading) _buildLoadingRow(),
          if (_recommendations != null) _buildRecommendations(context),
          _buildInput(context),
        ],
      ),
    );
  }

  Widget _buildHandle() => Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(2),
        ),
      );

  Widget _buildHeader(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy_outlined,
                  color: Colors.blue, size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Guía de Durango',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text('Agente IA · OpenRouter',
                    style: TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );

  Widget _buildLoadingRow() => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Text('El agente está pensando...',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      );

  Widget _buildRecommendations(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          border: Border(top: BorderSide(color: Colors.blue.shade100)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.touch_app, size: 16, color: Colors.blue),
                SizedBox(width: 6),
                Text(
                  'Toca un lugar para marcarlo en el mapa',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Colors.blue),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._recommendations!.map(
              (place) => _RecommendationCard(
                place: place,
                onTap: () {
                  Navigator.pop(context);
                  widget.onPlaceSelected(place);
                },
              ),
            ),
          ],
        ),
      );

  Widget _buildInput(BuildContext context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 12,
            right: 12,
            top: 8,
            bottom: MediaQuery.of(context).viewInsets.bottom + 8,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _input,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  decoration: InputDecoration(
                    hintText: 'Escribe tu preferencia...',
                    hintStyle:
                        const TextStyle(fontSize: 13, color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FloatingActionButton.small(
                heroTag: 'send_btn',
                onPressed: _loading ? null : _send,
                backgroundColor: _loading ? Colors.grey : Colors.blue,
                child: const Icon(Icons.send, size: 18),
              ),
            ],
          ),
        ),
      );
}

class _ChatBubble extends StatelessWidget {
  final bool isAgent;
  final String text;

  const _ChatBubble({required this.isAgent, required this.text});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isAgent ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: isAgent ? Colors.grey.shade100 : Colors.blue,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomLeft:
                isAgent ? const Radius.circular(2) : const Radius.circular(16),
            bottomRight:
                isAgent ? const Radius.circular(16) : const Radius.circular(2),
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 3,
                offset: const Offset(0, 1)),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isAgent ? Colors.black87 : Colors.white,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final PlaceRecommendation place;
  final VoidCallback onTap;

  const _RecommendationCard({required this.place, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.place, color: Colors.red, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    if (place.description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        place.description,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios,
                  size: 14, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
