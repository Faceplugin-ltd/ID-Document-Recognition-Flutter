import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/utils/result_parser.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key, required this.json});

  final String json;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  int tab = 0;

  static const _labels = ['Result', 'Security', 'Images', 'Raw JSON'];

  @override
  Widget build(BuildContext context) {
    final fieldRows = rows(widget.json);
    final secRows = securityRows(widget.json);
    final imgs = images(widget.json);
    final summaryText = summary(widget.json);
    final securityText = securitySummary(widget.json);
    final rawText = pretty(widget.json);

    return Scaffold(
      appBar: AppBar(title: const Text('Result')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  for (var i = 0; i < _labels.length; i++)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => tab = i),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: tab == i
                                ? AppColors.accent
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _labels[i],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: tab == i ? Colors.black : AppColors.text,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: switch (tab) {
              0 => _resultTab(summaryText, fieldRows),
              1 => _securityTab(securityText, secRows),
              2 => _imagesTab(imgs),
              _ => _rawTab(rawText),
            },
          ),
        ],
      ),
    );
  }

  Widget _resultTab(String summaryText, List<FieldRow> fieldRows) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          summaryText,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 15,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 16),
        const Row(
          children: [
            SizedBox(
              width: 64,
              child: Text(
                'Src',
                style: TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
            Expanded(
              child: Text(
                'Field',
                style: TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                'Value',
                style: TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const Divider(color: AppColors.border),
        for (var i = 0; i < fieldRows.length; i++)
          Container(
            color: i.isEven ? Colors.white.withValues(alpha: 0.03) : null,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 64,
                  child: Text(
                    fieldRows[i].source,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    fieldRows[i].key,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 13,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: SelectableText(
                    fieldRows[i].value,
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _securityTab(String securityText, List<SecurityRow> secRows) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          securityText,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 15,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 16),
        const Row(
          children: [
            Expanded(
              flex: 8,
              child: Text(
                'Page',
                style: TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
            Expanded(
              flex: 16,
              child: Text(
                'Check',
                style: TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
            Expanded(
              flex: 10,
              child: Text(
                'Status',
                style: TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const Divider(color: AppColors.border),
        if (secRows.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              'No security checks in this response',
              style: TextStyle(color: AppColors.muted),
            ),
          )
        else
          for (var i = 0; i < secRows.length; i++)
            Container(
              color: i.isEven ? Colors.white.withValues(alpha: 0.03) : null,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 8,
                    child: Text(
                      secRows[i].page,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 16,
                    child: Text(
                      secRows[i].check,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 10,
                    child: Text(
                      secRows[i].status,
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
      ],
    );
  }

  Widget _imagesTab(List<ResultImage> imgs) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: imgs.isEmpty
          ? const [
              Text(
                'No images in response.',
                style: TextStyle(color: AppColors.muted),
              ),
            ]
          : [
              for (final img in imgs) ...[
                Text(
                  img.source.isEmpty
                      ? img.category
                      : '${img.category} · ${img.source}',
                  style: const TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 220,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Image.memory(
                    img.bytes,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Text(
                        'Image decode failed',
                        style: TextStyle(color: AppColors.muted),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ],
    );
  }

  Widget _rawTab(String rawText) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SelectableText(
          rawText,
          style: const TextStyle(
            color: AppColors.text,
            fontFamily: 'monospace',
            fontSize: 12,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
