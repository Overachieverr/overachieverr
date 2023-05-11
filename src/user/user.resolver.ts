import { Args, Resolver } from "@nestjs/graphql";
import { User } from "./user.model";

@Resolver((of) => User)
export class UserResolver {
  constructor(private userService: userService) {}

  @Query((returns) => User)
  async user(@Args("id", { type: () => Int }) id: number) {
    return this.userService.user({ id: id });
  }
}
