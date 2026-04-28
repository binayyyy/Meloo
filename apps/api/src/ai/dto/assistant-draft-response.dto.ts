import { AiAssistantDraftIntent } from './assistant-draft-request.dto';

export class AiAssistantDraftResponseDto {
  intent!: AiAssistantDraftIntent;
  title!: string;
  content!: string;
}
