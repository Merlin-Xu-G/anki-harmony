// Error display component for AnkiHarmony
//
// Renders bridge errors with icons, descriptions, and optional retry button.
// Usage: ErrorView({ errorInfo: parseBridgeError(error) })

import { BridgeErrorInfo } from '../utils/BridgeErrorUtils';

@Component
export struct ErrorView {
  /** Parsed error to display. */
  errorInfo: BridgeErrorInfo;
  /** Callback when the retry button is pressed. If undefined, no retry button shown. */
  onRetry?: () => void;

  build() {
    Column({ space: 8 }) {
      // Error icon + title
      Row({ space: 8 }) {
        SymbolGlyph($r('sys.symbol.exclamationmark_triangle_fill'))
          .fontSize(20)
          .fontColor('#FF6B6B');
        Text('Error')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FF6B6B');
      }
      .alignItems(VerticalAlign.Center);

      // Error description
      Text(this.errorInfo.displayMessage)
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))
        .lineHeight(20);

      // Detail message (collapsed by default for long messages)
      if (this.errorInfo.message.length > 0 && this.errorInfo.message !== this.errorInfo.displayMessage) {
        Text(this.errorInfo.message)
          .fontSize(12)
          .fontColor($r('app.color.text_tertiary'))
          .maxLines(3)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .opacity(0.7);
      }

      // Error code badge
      Text(this.errorInfo.code)
        .fontSize(11)
        .fontColor($r('app.color.text_tertiary'))
        .backgroundColor('#2A2A2A')
        .padding({ left: 8, right: 8, top: 2, bottom: 2 })
        .borderRadius(4);

      // Retry button (if retryable and callback provided)
      if (this.onRetry && this.errorInfo.retryable) {
        Button('Retry')
          .type(ButtonType.Capsule)
          .fontSize(14)
          .fontColor($r('app.color.text_primary'))
          .backgroundColor('#4A90D9')
          .width(120)
          .height(36)
          .margin({ top: 12 })
          .onClick(() => {
            if (this.onRetry) {
              this.onRetry();
            }
          });
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#1E1E1E')
    .borderRadius(12);
  }
}
