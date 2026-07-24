import 'package:flutter/material.dart';

import '../../domain/entities/agent_type.dart';

class AgentSelector extends StatelessWidget {
  const AgentSelector({required this.selected, required this.onSelected, super.key});
  final AgentType selected;
  final ValueChanged<AgentType> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          for (final agent in AgentType.chatAgents)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text(agent.label),
                selected: selected == agent,
                onSelected: (_) => onSelected(agent),
              ),
            ),
        ],
      ),
    );
  }
}
