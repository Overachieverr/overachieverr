import { Controller, Get } from '@nestjs/common';
import { User as UserModel } from '../../prisma/client';
import { UserService } from './user.service';

@Controller()
export class UserController {
  constructor(private readonly userService: UserService) {}

  @Get('users')
  async getAllUsers(): Promise<UserModel[]> {
    return this.userService.users({})
  }
}
