import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { JsonApiModule } from 'json-api-nestjs';
import { User } from './users/user.entity';

@Module({
  imports: [
    TypeOrmModule.forRoot({
      type: 'better-sqlite3',
      database: '/app/db.sqlite3',
      synchronize: process.env.NODE_ENV !== 'production',
      entities: [User],
    }),
    JsonApiModule.forRoot({
      entities: [User],
      options: {
        requiredSelectField: false
      }
    })
  ],
})
export class AppModule {}
