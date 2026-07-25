import 'package:flutter/material.dart';

import '../../../../core/widgets/app_chip.dart';
import '../../domain/entities/agent_type.dart';

class AgentSelector extends StatelessWidget {
  const AgentSelector({required this.selected, required this.onSelected, super.key});
  final AgentType selected;
  final ValueChanged<AgentType> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          for (final agent in AgentType.chatAgents)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: AppChip(
                label: agent.label,
                selected: selected == agent,
                onTap: () => onSelected(agent),
              ),
            ),
        ],
      ),
    );
  }
}
