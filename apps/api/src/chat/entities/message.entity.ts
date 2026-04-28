import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { DATE_COLUMN_TYPE, ENUM_COLUMN_TYPE } from '../../database/database-column-types';
import { User } from '../../users/entities';
import { Conversation } from './conversation.entity';

export enum MessageType {
  TEXT = 'text',
  ASSISTANT = 'assistant',
  SYSTEM = 'system',
}

@Entity({ name: 'messages' })
export class Message {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'uuid', name: 'conversation_id' })
  conversationId!: string;

  @Column({ type: 'uuid', name: 'sender_id' })
  senderId!: string;

  @Column({ type: 'text' })
  body!: string;

  @Column({
    type: ENUM_COLUMN_TYPE,
    enum: MessageType,
    default: MessageType.TEXT,
    name: 'message_type',
  })
  messageType!: MessageType;

  @CreateDateColumn({ type: DATE_COLUMN_TYPE, name: 'created_at' })
  createdAt!: Date;

  @ManyToOne(() => Conversation, (conversation) => conversation.messages, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'conversation_id' })
  conversation!: Conversation;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'sender_id' })
  sender!: User;
}
